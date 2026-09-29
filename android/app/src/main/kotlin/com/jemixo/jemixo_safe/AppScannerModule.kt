package com.jemixo.jemixo_safe

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Installed application inventory + APK metadata extraction.
 *
 * Exposes raw, platform-reported facts only. Interpretation (risk scoring,
 * "suspicious" classification) lives in the Dart risk engine so the rules stay
 * updatable without a native release.
 *
 * Works with or without QUERY_ALL_PACKAGES: the launcher query in the manifest
 * always reveals every app the user can open, and those are merged in.
 */
class AppScannerModule(private val context: Context) {

    private val pm: PackageManager get() = context.packageManager

    /** Permissions + signing certificates in a single PackageManager round trip. */
    private val fullFlags: Int
        get() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            PackageManager.GET_PERMISSIONS or PackageManager.GET_SIGNING_CERTIFICATES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_PERMISSIONS or PackageManager.GET_SIGNATURES
        }

    /** Whether the full package list is visible or only launchable apps. */
    fun packageVisibility(): Map<String, Any?> {
        val full = Build.VERSION.SDK_INT < Build.VERSION_CODES.R ||
            BridgeUtil.hasPermission(context, Manifest.permission.QUERY_ALL_PACKAGES)
        return mapOf("full" to full, "sdkInt" to Build.VERSION.SDK_INT)
    }

    fun getInstalledApps(call: MethodCall, result: MethodChannel.Result) {
        try {
            val includeSystem = call.argument<Boolean>("includeSystem") ?: true
            val byPackage = LinkedHashMap<String, PackageInfo>()

            val packages = try {
                installedPackages(fullFlags)
            } catch (_: Throwable) {
                // TransactionTooLargeException on devices with hundreds of apps:
                // fall back to a lean list and enrich each entry individually.
                installedPackages(0).mapNotNull { getPackageInfo(it.packageName, fullFlags) }
            }
            for (info in packages) byPackage[info.packageName] = info

            // Launchable apps are visible without QUERY_ALL_PACKAGES.
            val launchable = launchablePackages().toHashSet()
            for (packageName in launchable) {
                if (byPackage.containsKey(packageName)) continue
                getPackageInfo(packageName, fullFlags)?.let { byPackage[packageName] = it }
            }

            val selfPackage = context.packageName
            val list = ArrayList<Map<String, Any?>>(byPackage.size)
            for (info in byPackage.values) {
                val appInfo = info.applicationInfo ?: continue
                if (isSystem(appInfo) && !includeSystem) continue
                if (info.packageName == selfPackage) continue
                list.add(describePackage(info, appInfo, launchable.contains(info.packageName)))
            }
            result.success(list)
        } catch (t: Throwable) {
            result.error("APP_LIST_FAILED", t.message ?: "Unable to read installed applications", null)
        }
    }

    fun getAppDetails(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.error("BAD_ARGS", "packageName is required", null)
            return
        }
        try {
            val info = getPackageInfo(packageName, fullFlags)
            val appInfo = info?.applicationInfo
            if (info == null || appInfo == null) {
                result.success(null)
                return
            }
            result.success(describePackage(info, appInfo, launchablePackages().contains(packageName)))
        } catch (t: Throwable) {
            result.error("APP_DETAIL_FAILED", t.message, null)
        }
    }

    /** Opens Android's own App info screen for [packageName]. */
    fun openAppSettings(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.error("BAD_ARGS", "packageName is required", null)
            return
        }
        result.success(
            BridgeUtil.openSettings(
                context,
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                packageName,
            )
        )
    }

    /**
     * Hands off to the system uninstall dialog. Android asks for confirmation
     * itself; nothing is removed by this app.
     */
    fun openAppUninstall(call: MethodCall, result: MethodChannel.Result) {
        val packageName = call.argument<String>("packageName")
        if (packageName.isNullOrBlank()) {
            result.error("BAD_ARGS", "packageName is required", null)
            return
        }
        val opened = try {
            context.startActivity(
                Intent(Intent.ACTION_DELETE, Uri.fromParts("package", packageName, null)).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            true
        } catch (_: Throwable) {
            // Fall back to App info, which always has an Uninstall button.
            BridgeUtil.openSettings(context, Settings.ACTION_APPLICATION_DETAILS_SETTINGS, packageName)
        }
        result.success(opened)
    }

    fun openSystemSettings(call: MethodCall, result: MethodChannel.Result) {
        val action = call.argument<String>("action")
        if (action.isNullOrBlank()) {
            result.error("BAD_ARGS", "action is required", null)
            return
        }
        val withPackage = call.argument<Boolean>("withPackage") ?: false
        result.success(
            BridgeUtil.openSettings(context, action, if (withPackage) context.packageName else null)
        )
    }

    // region internals

    private fun launchablePackages(): List<String> = try {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(launcher, PackageManager.ResolveInfoFlags.of(0L))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(launcher, 0)
        }
        activities.mapNotNull { it.activityInfo?.packageName }.distinct()
    } catch (_: Throwable) {
        emptyList()
    }

    private fun installedPackages(flags: Int): List<PackageInfo> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getInstalledPackages(PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getInstalledPackages(flags)
        }

    private fun getPackageInfo(packageName: String, flags: Int): PackageInfo? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            pm.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(flags.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.getPackageInfo(packageName, flags)
        }
    } catch (_: Throwable) {
        null
    }

    private fun isSystem(appInfo: ApplicationInfo): Boolean =
        (appInfo.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
            (appInfo.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0

    private fun describePackage(
        info: PackageInfo,
        appInfo: ApplicationInfo,
        hasLauncherIcon: Boolean,
    ): Map<String, Any?> {
        val packageName = info.packageName
        val permissions = (info.requestedPermissions ?: emptyArray()).map { mapOf("name" to it) }

        var sizeBytes: Long? = null
        try {
            val apk = File(appInfo.sourceDir ?: "")
            if (apk.exists()) {
                var total = apk.length()
                appInfo.splitSourceDirs?.forEach { path ->
                    val f = File(path)
                    if (f.exists()) total += f.length()
                }
                sizeBytes = total
            }
        } catch (_: Throwable) {
            sizeBytes = null
        }

        return mapOf(
            "packageName" to packageName,
            "label" to safeLabel(info, appInfo),
            "versionName" to info.versionName,
            "versionCode" to versionCode(info),
            "minSdk" to appInfo.minSdkVersion,
            "targetSdk" to appInfo.targetSdkVersion,
            "sizeBytes" to sizeBytes,
            "isSystemApp" to isSystem(appInfo),
            "isEnabled" to appInfo.enabled,
            "installTime" to BridgeUtil.epochMillis(info.firstInstallTime),
            "lastUpdateTime" to BridgeUtil.epochMillis(info.lastUpdateTime),
            "sourceDir" to appInfo.sourceDir,
            "installerPackage" to installerOf(packageName),
            "debuggable" to ((appInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0),
            "hasCode" to ((appInfo.flags and ApplicationInfo.FLAG_HAS_CODE) != 0),
            "hasLauncherIcon" to hasLauncherIcon,
            "requestedPermissions" to permissions,
            "signatures" to signaturesOf(info),
        )
    }

    private fun safeLabel(info: PackageInfo, appInfo: ApplicationInfo): String = try {
        appInfo.loadLabel(pm).toString().ifBlank { info.packageName }
    } catch (_: Throwable) {
        info.packageName
    }

    private fun versionCode(info: PackageInfo): Long? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            @Suppress("DEPRECATION")
            info.versionCode.toLong()
        }
    } catch (_: Throwable) {
        null
    }

    private fun installerOf(packageName: String): String? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            pm.getInstallSourceInfo(packageName).installingPackageName
        } else {
            @Suppress("DEPRECATION")
            pm.getInstallerPackageName(packageName)
        }
    } catch (_: Throwable) {
        null
    }

    private fun signaturesOf(info: PackageInfo): List<Map<String, String?>> = try {
        val signatures: Array<Signature>? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signing = info.signingInfo
            when {
                signing == null -> null
                signing.hasMultipleSigners() -> signing.apkContentsSigners
                else -> signing.signingCertificateHistory
            }
        } else {
            @Suppress("DEPRECATION")
            info.signatures
        }

        signatures?.map {
            mapOf(
                "sha256" to BridgeUtil.signatureSha256(it),
                "md5" to BridgeUtil.signatureMd5(it),
            )
        } ?: emptyList()
    } catch (_: Throwable) {
        emptyList()
    }

    // endregion
}
