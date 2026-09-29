package com.jemixo.jemixo_safe

import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.net.Uri
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.zip.ZipFile

/**
 * Static APK inspection for a user-selected file.
 *
 * Uses PackageManager.getPackageArchiveInfo so results match what Android would
 * install, plus a light binary-manifest probe for flags the archive API does
 * not surface. Accepts an absolute path or a content URI (copied to cache).
 */
class ApkAnalyzerModule(private val context: Context) {

    fun analyzeApk(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("path")
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "path is required", null)
            return
        }
        val file = resolveFile(target)
        if (file == null || !file.exists() || !file.isFile) {
            result.error("APK_NOT_FOUND", "File not found", null)
            return
        }
        val path = file.absolutePath

        try {
            val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                PackageManager.GET_PERMISSIONS or PackageManager.GET_SIGNING_CERTIFICATES
            } else {
                @Suppress("DEPRECATION")
                PackageManager.GET_PERMISSIONS or PackageManager.GET_SIGNATURES
            }

            val info: PackageInfo? = try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                    context.packageManager.getPackageArchiveInfo(path, PackageManager.PackageInfoFlags.of(flags.toLong()))
                } else {
                    @Suppress("DEPRECATION")
                    context.packageManager.getPackageArchiveInfo(path, flags)
                }
            } catch (_: Throwable) {
                null
            }

            if (info == null) {
                result.success(
                    mapOf(
                        "valid" to false,
                        "fileName" to file.name,
                        "path" to path,
                        "sizeBytes" to file.length(),
                        "modified" to file.lastModified(),
                        "message" to "This file could not be parsed as a valid Android package.",
                    )
                )
                return
            }

            val appInfo = info.applicationInfo?.apply {
                // Archive infos have no source dir, which loadLabel needs to
                // resolve string resources inside the package.
                sourceDir = path
                publicSourceDir = path
            }

            val zip = ZipInspection.of(file)

            result.success(
                mapOf(
                    "valid" to true,
                    "fileName" to file.name,
                    "path" to path,
                    "sizeBytes" to file.length(),
                    "modified" to file.lastModified(),
                    "packageName" to info.packageName,
                    "label" to safeLabel(appInfo),
                    "versionName" to info.versionName,
                    "versionCode" to versionCode(info),
                    "minSdk" to appInfo?.minSdkVersion,
                    "targetSdk" to appInfo?.targetSdkVersion,
                    "debuggable" to (appInfo?.let { (it.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0 }
                        ?: zip.debuggableHint),
                    "requestedPermissions" to (info.requestedPermissions ?: emptyArray())
                        .map { mapOf("name" to it) },
                    "signatures" to extractSignatures(info),
                    "usesCleartextTraffic" to zip.cleartextHint,
                    "hasNativeCode" to zip.hasNativeLibs,
                    "entryCount" to zip.entryCount,
                    "installedVersionCode" to installedVersionCode(info.packageName),
                )
            )
        } catch (t: Throwable) {
            result.error("APK_ANALYSIS_FAILED", t.message, null)
        }
    }

    private fun resolveFile(target: String): File? {
        if (!target.startsWith("content://")) return File(target)
        return try {
            val uri = Uri.parse(target)
            val dir = File(context.cacheDir, "shared").apply { mkdirs() }
            val name = BridgeUtil.displayName(context, uri)?.takeIf { it.isNotBlank() } ?: "picked.apk"
            val out = File(dir, name.replace(Regex("[^A-Za-z0-9._-]"), "_"))
            context.contentResolver.openInputStream(uri)?.use { input ->
                out.outputStream().use { input.copyTo(it) }
            } ?: return null
            out
        } catch (_: Throwable) {
            null
        }
    }

    private fun safeLabel(appInfo: ApplicationInfo?): String? = try {
        appInfo?.loadLabel(context.packageManager)?.toString()?.takeIf { it.isNotBlank() }
    } catch (_: Throwable) {
        null
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

    /** Version of the same package already installed, if any. */
    private fun installedVersionCode(packageName: String?): Long? = try {
        if (packageName == null) {
            null
        } else {
            val installed = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(packageName, PackageManager.PackageInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, 0)
            }
            versionCode(installed)
        }
    } catch (_: Throwable) {
        null
    }

    private fun extractSignatures(info: PackageInfo): List<Map<String, String?>> = try {
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
            mapOf("sha256" to BridgeUtil.signatureSha256(it), "md5" to BridgeUtil.signatureMd5(it))
        } ?: emptyList()
    } catch (_: Throwable) {
        emptyList()
    }

    /** Everything we want from the archive, gathered in a single pass. */
    private class ZipInspection(
        val hasNativeLibs: Boolean,
        val entryCount: Int,
        val debuggableHint: Boolean,
        val cleartextHint: Boolean?,
    ) {
        companion object {
            fun of(file: File): ZipInspection = try {
                ZipFile(file).use { zip ->
                    var native = false
                    var count = 0
                    for (entry in zip.entries()) {
                        count++
                        if (!native && entry.name.startsWith("lib/") && entry.name.endsWith(".so")) {
                            native = true
                        }
                    }
                    // AAPT binary manifests keep attribute names in a string
                    // pool, so a substring scan is a hint only, never proof.
                    var debuggable = false
                    var cleartext: Boolean? = null
                    zip.getEntry("AndroidManifest.xml")?.let { manifest ->
                        val text = zip.getInputStream(manifest).use { String(it.readBytes(), Charsets.ISO_8859_1) }
                        debuggable = text.contains("debuggable")
                        cleartext = if (text.contains("usesCleartextTraffic")) true else null
                    }
                    ZipInspection(native, count, debuggable, cleartext)
                }
            } catch (_: Throwable) {
                ZipInspection(false, 0, false, null)
            }
        }
    }
}
