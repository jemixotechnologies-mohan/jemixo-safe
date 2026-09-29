package com.jemixo.jemixo_safe

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.work.Configuration
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import androidx.work.Worker
import androidx.work.WorkerParameters
import java.util.concurrent.TimeUnit

/**
 * Periodic check for newly installed user apps. Compares the current package
 * set with the last one seen and posts one notification per new app that
 * came from outside a store or asks for sensitive access.
 *
 * No broadcast receivers, no foreground service: WorkManager wakes it every
 * 30 minutes, which is enough to catch a sideload the user did not expect.
 */
class InstallWatchWorker(context: Context, params: WorkerParameters) : Worker(context, params) {

    override fun doWork(): Result {
        val context = applicationContext
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val known = prefs.getStringSet(KEY_KNOWN, null)
        val current = userPackages(context)

        if (known == null) {
            // First run: just record the baseline, never alert on it.
            prefs.edit().putStringSet(KEY_KNOWN, current.keys).apply()
            return Result.success()
        }

        val fresh = current.filterKeys { it !in known }
        for ((packageName, info) in fresh) {
            val flags = sensitiveFlags(context, packageName)
            val sideloaded = !isStoreInstall(context, packageName)
            if (!sideloaded && flags.isEmpty()) continue
            notify(context, packageName, info, sideloaded, flags)
        }

        prefs.edit().putStringSet(KEY_KNOWN, current.keys).apply()
        return Result.success()
    }

    private fun userPackages(context: Context): Map<String, ApplicationInfo> {
        val pm = context.packageManager
        val result = HashMap<String, ApplicationInfo>()
        val installed = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                pm.getInstalledApplications(PackageManager.ApplicationInfoFlags.of(0L))
            } else {
                @Suppress("DEPRECATION")
                pm.getInstalledApplications(0)
            }
        } catch (_: Throwable) {
            emptyList()
        }
        for (info in installed) {
            val system = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (system || info.packageName == context.packageName) continue
            result[info.packageName] = info
        }
        // Launcher fallback for devices where QUERY_ALL_PACKAGES is not granted.
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val activities = try {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(launcher, 0)
        } catch (_: Throwable) {
            emptyList()
        }
        for (resolve in activities) {
            val info = resolve.activityInfo?.applicationInfo ?: continue
            val system = (info.flags and ApplicationInfo.FLAG_SYSTEM) != 0
            if (system || info.packageName == context.packageName) continue
            result.putIfAbsent(info.packageName, info)
        }
        return result
    }

    private fun sensitiveFlags(context: Context, packageName: String): List<String> {
        val permissions = try {
            val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                context.packageManager.getPackageInfo(
                    packageName,
                    PackageManager.PackageInfoFlags.of(PackageManager.GET_PERMISSIONS.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getPackageInfo(packageName, PackageManager.GET_PERMISSIONS)
            }
            info.requestedPermissions?.toSet() ?: emptySet()
        } catch (_: Throwable) {
            emptySet()
        }
        val flags = ArrayList<String>()
        if (permissions.any { it.contains("SMS") }) flags.add("SMS")
        if ("android.permission.READ_CONTACTS" in permissions) flags.add("contacts")
        if ("android.permission.BIND_ACCESSIBILITY_SERVICE" in permissions) flags.add("accessibility")
        if ("android.permission.SYSTEM_ALERT_WINDOW" in permissions) flags.add("overlay")
        if ("android.permission.BIND_DEVICE_ADMIN" in permissions) flags.add("device admin")
        return flags
    }

    private fun isStoreInstall(context: Context, packageName: String): Boolean {
        val installer = try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.packageManager.getInstallSourceInfo(packageName).installingPackageName
            } else {
                @Suppress("DEPRECATION")
                context.packageManager.getInstallerPackageName(packageName)
            }
        } catch (_: Throwable) {
            null
        }
        return installer != null && installer in STORE_INSTALLERS
    }

    private fun notify(
        context: Context,
        packageName: String,
        info: ApplicationInfo,
        sideloaded: Boolean,
        sensitive: List<String>,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !BridgeUtil.hasPermission(context, Manifest.permission.POST_NOTIFICATIONS)
        ) {
            return
        }
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
        ensureChannel(context, manager)

        val label = try {
            info.loadLabel(context.packageManager).toString()
        } catch (_: Throwable) {
            packageName
        }
        val reasons = ArrayList<String>()
        if (sideloaded) reasons.add("installed outside a known store")
        if (sensitive.isNotEmpty()) reasons.add("asks for ${sensitive.joinToString(", ")}")

        val open = Intent(context, MainActivity::class.java).apply {
            action = MainActivity.ACTION_OPEN_PACKAGE
            putExtra(MainActivity.EXTRA_PACKAGE, packageName)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pending = PendingIntent.getActivity(
            context,
            packageName.hashCode(),
            open,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_tile_shield)
            .setContentTitle("New app: $label")
            .setContentText("This app was ${reasons.joinToString(" and ")}. Tap to review.")
            .setStyle(
                NotificationCompat.BigTextStyle().bigText(
                    "$label was ${reasons.joinToString(" and ")}. Jemixo Safe never removes " +
                        "apps; tap to see what it can access and decide for yourself.",
                )
            )
            .setContentIntent(pending)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .build()
        manager.notify(packageName.hashCode(), notification)
    }

    private fun ensureChannel(context: Context, manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            context.getString(R.string.notification_channel_installs),
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply {
            description = context.getString(R.string.notification_channel_installs_description)
        }
        manager.createNotificationChannel(channel)
    }

    companion object {
        private const val PREFS = "jemixo_install_watch"
        private const val KEY_KNOWN = "known_packages"
        private const val WORK_NAME = "install_watch"
        const val CHANNEL_ID = "new_app_alerts"

        private val STORE_INSTALLERS = setOf(
            "com.android.vending",
            "com.amazon.venezia",
            "com.sec.android.app.samsungapps",
            "com.huawei.appmarket",
            "com.xiaomi.mipicks",
            "com.xiaomi.market",
            "com.oppo.market",
            "com.heytap.market",
            "com.vivo.appstore",
            "com.bbk.appstore",
            "com.oneplus.store",
        )

        private fun workManager(context: Context): WorkManager {
            // Automatic initialisation is disabled in the manifest so the
            // worker never runs unless the user enabled alerts.
            try {
                WorkManager.initialize(context, Configuration.Builder().build())
            } catch (_: IllegalStateException) {
                // Already initialised.
            }
            return WorkManager.getInstance(context)
        }

        fun setEnabled(context: Context, enabled: Boolean) {
            val manager = workManager(context)
            if (!enabled) {
                manager.cancelUniqueWork(WORK_NAME)
                context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().clear().apply()
                return
            }
            val request = PeriodicWorkRequestBuilder<InstallWatchWorker>(30, TimeUnit.MINUTES)
                .build()
            manager.enqueueUniquePeriodicWork(WORK_NAME, ExistingPeriodicWorkPolicy.KEEP, request)
        }

        fun isEnabled(context: Context): Boolean = try {
            val infos = workManager(context).getWorkInfosForUniqueWork(WORK_NAME).get()
            infos.any { !it.state.isFinished }
        } catch (_: Throwable) {
            false
        }
    }
}
