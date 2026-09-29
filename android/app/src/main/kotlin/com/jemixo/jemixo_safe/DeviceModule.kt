package com.jemixo.jemixo_safe

import android.app.ActivityManager
import android.app.AppOpsManager
import android.app.KeyguardManager
import android.app.admin.DevicePolicyManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import android.os.BatteryManager
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.os.Process
import android.os.StatFs
import android.provider.Settings
import android.telephony.TelephonyManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Device health: hardware identity, battery, network and sensor availability.
 *
 * Reports only what Android actually exposes. Where a value is unavailable the
 * map omits it rather than substituting a guess — the spec explicitly forbids
 * invented battery-health percentages.
 */
class DeviceModule(private val context: Context) {

    private val mainHandler = Handler(Looper.getMainLooper())

    fun getDeviceInfo(call: MethodCall, result: MethodChannel.Result) {
        try {
            result.success(deviceInfoMap())
        } catch (t: Throwable) {
            result.error("DEVICE_INFO_FAILED", t.message, null)
        }
    }

    fun getBatteryInfo(call: MethodCall, result: MethodChannel.Result) {
        try {
            val battery: Intent? = context.registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            if (battery == null) {
                result.success(null)
                return
            }

            val level = battery.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
            val scale = battery.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
            val percent = if (level >= 0 && scale > 0) (level * 100.0 / scale).toInt() else null
            val statusCode = battery.getIntExtra(BatteryManager.EXTRA_STATUS, -1)
            val plugged = battery.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1)
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val isCharging = plugged > 0 ||
                statusCode == BatteryManager.BATTERY_STATUS_CHARGING ||
                statusCode == BatteryManager.BATTERY_STATUS_FULL

            result.success(
                mapOf(
                    "percent" to percent,
                    "isCharging" to isCharging,
                    "statusCode" to statusCode,
                    "isPowerSaveMode" to powerManager.isPowerSaveMode,
                    "temperatureCelsius" to battery.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0)
                        .takeIf { it != 0 }?.let { it / 10.0 },
                    "voltageMillivolts" to battery.getIntExtra(BatteryManager.EXTRA_VOLTAGE, 0)
                        .takeIf { it > 0 },
                    "technology" to battery.getStringExtra(BatteryManager.EXTRA_TECHNOLOGY),
                    "healthCode" to battery.getIntExtra(BatteryManager.EXTRA_HEALTH, -1),
                    "chargeCounterMah" to chargeCounterMah(),
                )
            )
        } catch (t: Throwable) {
            result.error("BATTERY_INFO_FAILED", t.message, null)
        }
    }

    fun getBatteryUsage(call: MethodCall, result: MethodChannel.Result) {
        val limitHours = call.argument<Number>("hours")?.toInt() ?: 24
        try {
            val usageManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
            if (usageManager == null) {
                result.success(emptyList<Map<String, Any?>>())
                return
            }
            val now = System.currentTimeMillis()
            val rows = usageManager
                .queryAndAggregateUsageStats(now - limitHours * 3600_000L, now)
                .values
                .filter { it.totalTimeInForeground > 0L }
                .sortedByDescending { it.totalTimeInForeground }
                .take(15)
                .map {
                    mapOf<String, Any?>(
                        "packageName" to it.packageName,
                        "foregroundMillis" to it.totalTimeInForeground,
                        "lastTimeUsed" to it.lastTimeUsed,
                    )
                }
            result.success(rows)
        } catch (t: Throwable) {
            result.error("BATTERY_USAGE_FAILED", t.message, null)
        }
    }

    fun getNetworkInfo(call: MethodCall, result: MethodChannel.Result) {
        try {
            val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
            if (cm == null) {
                result.success(mapOf("available" to false))
                return
            }

            val network = cm.activeNetwork
            val capabilities = network?.let { cm.getNetworkCapabilities(it) }
            val connected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
            val validated = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED) == true

            val type: String? = when {
                capabilities == null -> null
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN) -> "vpn"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> "cellular"
                capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
                else -> "other"
            }

            val wifiManager = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
            val ssid = try {
                @Suppress("DEPRECATION")
                wifiManager?.connectionInfo?.ssid?.trim('"')
                    ?.takeIf { it.isNotBlank() && it != "<unknown ssid>" }
            } catch (_: Throwable) {
                null
            }

            result.success(
                mapOf(
                    "available" to true,
                    "connected" to connected,
                    "validated" to validated,
                    "type" to type,
                    "wifiName" to ssid,
                    "metered" to (capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED) == false),
                    "downstreamKbps" to capabilities?.linkDownstreamBandwidthKbps?.takeIf { it > 0 },
                    "upstreamKbps" to capabilities?.linkUpstreamBandwidthKbps?.takeIf { it > 0 },
                    "carrierName" to carrierName(),
                )
            )
        } catch (t: Throwable) {
            result.error("NETWORK_INFO_FAILED", t.message, null)
        }
    }

    fun getSensors(call: MethodCall, result: MethodChannel.Result) {
        try {
            val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
            val sensors = manager?.getSensorList(Sensor.TYPE_ALL)?.map {
                mapOf(
                    "name" to it.name,
                    "type" to it.type,
                    "vendor" to it.vendor,
                    "version" to it.version,
                    "powerMah" to it.power,
                    "resolution" to it.resolution,
                    "maxRange" to it.maximumRange,
                )
            } ?: emptyList()
            result.success(sensors)
        } catch (t: Throwable) {
            result.error("SENSOR_LIST_FAILED", t.message, null)
        }
    }

    /**
     * Listens to one sensor type for `durationMs` and reports how many events
     * arrived plus the last / min / max of the first value. Used for sensors
     * that have no Flutter plugin stream (proximity, light).
     */
    fun sampleSensor(call: MethodCall, result: MethodChannel.Result) {
        val type = call.argument<Number>("type")?.toInt()
        val durationMs = (call.argument<Number>("durationMs")?.toLong() ?: 4000L).coerceIn(500L, 15_000L)
        val manager = context.getSystemService(Context.SENSOR_SERVICE) as? SensorManager
        val sensor = type?.let { manager?.getDefaultSensor(it) }
        if (manager == null || sensor == null) {
            result.success(mapOf("available" to false, "readings" to 0))
            return
        }

        var readings = 0
        var last: List<Float> = emptyList()
        var min = Float.MAX_VALUE
        var max = -Float.MAX_VALUE
        var delivered = false

        val listener = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                readings++
                last = event.values.toList()
                val v = event.values.firstOrNull() ?: return
                if (v < min) min = v
                if (v > max) max = v
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit
        }

        fun finish() {
            if (delivered) return
            delivered = true
            try {
                manager.unregisterListener(listener)
            } catch (_: Throwable) {
            }
            result.success(
                mapOf(
                    "available" to true,
                    "readings" to readings,
                    "last" to last,
                    "min" to if (readings == 0) null else min,
                    "max" to if (readings == 0) null else max,
                    "maxRange" to sensor.maximumRange,
                )
            )
        }

        val registered = try {
            manager.registerListener(listener, sensor, SensorManager.SENSOR_DELAY_UI)
        } catch (_: Throwable) {
            false
        }
        if (!registered) {
            result.success(mapOf("available" to false, "readings" to 0))
            return
        }
        mainHandler.postDelayed({ finish() }, durationMs)
    }

    fun getSecuritySettings(call: MethodCall, result: MethodChannel.Result) {
        try {
            val keyguard = context.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            val deviceSecure = keyguard?.isDeviceSecure ?: false

            val accessibilityEnabled = try {
                val enabled = Settings.Secure.getString(
                    context.contentResolver,
                    Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES,
                )
                !enabled.isNullOrBlank() && enabled.split(":").any { it.isNotBlank() }
            } catch (_: Throwable) {
                false
            }

            val overlayGranted = try {
                Settings.canDrawOverlays(context)
            } catch (_: Throwable) {
                false
            }

            val deviceAdminCount = try {
                val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                dpm?.activeAdmins?.size ?: 0
            } catch (_: Throwable) {
                0
            }

            val usageAccessGranted = try {
                val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
                val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    appOps?.unsafeCheckOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        Process.myUid(),
                        context.packageName,
                    )
                } else {
                    @Suppress("DEPRECATION")
                    appOps?.checkOpNoThrow(
                        AppOpsManager.OPSTR_GET_USAGE_STATS,
                        Process.myUid(),
                        context.packageName,
                    )
                }
                mode == AppOpsManager.MODE_ALLOWED
            } catch (_: Throwable) {
                false
            }

            result.success(
                mapOf(
                    "deviceSecure" to deviceSecure,
                    "accessibilityServicesEnabled" to accessibilityEnabled,
                    "overlayPermissionGranted" to overlayGranted,
                    "activeDeviceAdmins" to deviceAdminCount,
                    "usageAccessGranted" to usageAccessGranted,
                    "unknownSourcesAllowed" to unknownSourcesAllowed(),
                    "developerOptionsEnabled" to developerOptionsEnabled(),
                    "adbEnabled" to adbEnabled(),
                )
            )
        } catch (t: Throwable) {
            result.error("SECURITY_SETTINGS_FAILED", t.message, null)
        }
    }

    /**
     * Apps holding the three capabilities that banking trojans and stalkerware
     * rely on: accessibility services, notification access and device admin.
     * All three lists are public settings; no permission is needed to read them.
     */
    fun getSpecialAccess(call: MethodCall, result: MethodChannel.Result) {
        try {
            fun components(key: String): List<String> = try {
                Settings.Secure.getString(context.contentResolver, key)
                    ?.split(':')
                    ?.map { it.trim() }
                    ?.filter { it.isNotEmpty() }
                    ?: emptyList()
            } catch (_: Throwable) {
                emptyList()
            }

            fun describe(component: String): Map<String, Any?> {
                val packageName = component.substringBefore('/')
                val (label, system) = try {
                    val info = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        context.packageManager.getApplicationInfo(
                            packageName,
                            PackageManager.ApplicationInfoFlags.of(0L),
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        context.packageManager.getApplicationInfo(packageName, 0)
                    }
                    info.loadLabel(context.packageManager).toString() to
                        ((info.flags and android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0)
                } catch (_: Throwable) {
                    packageName to false
                }
                return mapOf(
                    "packageName" to packageName,
                    "component" to component,
                    "label" to label,
                    "isSystemApp" to system,
                )
            }

            val accessibility = components(Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES)
            val listeners = components("enabled_notification_listeners")
            val admins = try {
                val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
                dpm?.activeAdmins?.map { it.flattenToString() } ?: emptyList()
            } catch (_: Throwable) {
                emptyList()
            }

            result.success(
                mapOf(
                    "accessibility" to accessibility.map(::describe),
                    "notificationListeners" to listeners.map(::describe),
                    "deviceAdmins" to admins.map(::describe),
                )
            )
        } catch (t: Throwable) {
            result.error("SPECIAL_ACCESS_FAILED", t.message, null)
        }
    }

    fun getMemoryInfo(call: MethodCall, result: MethodChannel.Result) {
        try {
            val am = context.getSystemService(Context.ACTIVITY_SERVICE) as? ActivityManager
            val info = ActivityManager.MemoryInfo()
            am?.getMemoryInfo(info)
            val stat = StatFs(Environment.getDataDirectory().path)

            result.success(
                mapOf(
                    "totalRamBytes" to info.totalMem,
                    "availableRamBytes" to info.availMem,
                    "lowMemory" to info.lowMemory,
                    "thresholdBytes" to info.threshold,
                    "totalDataBytes" to stat.blockCountLong * stat.blockSizeLong,
                    "freeDataBytes" to stat.availableBlocksLong * stat.blockSizeLong,
                )
            )
        } catch (t: Throwable) {
            result.error("MEMORY_INFO_FAILED", t.message, null)
        }
    }

    fun openUsageAccessSettings(call: MethodCall, result: MethodChannel.Result) {
        result.success(BridgeUtil.openSettings(context, Settings.ACTION_USAGE_ACCESS_SETTINGS))
    }

    fun openBatteryOptimizationSettings(call: MethodCall, result: MethodChannel.Result) {
        result.success(
            BridgeUtil.openSettings(context, Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS) ||
                BridgeUtil.openSettings(context, Settings.ACTION_BATTERY_SAVER_SETTINGS)
        )
    }

    /**
     * Turns the camera torch on or off so the hardware test screen can confirm
     * the flash unit works. Returns the resulting state, or null when the
     * device has no controllable flash.
     */
    fun setFlash(call: MethodCall, result: MethodChannel.Result) {
        val enabled = call.argument<Boolean>("enabled") ?: false
        val cameraManager = context.getSystemService(Context.CAMERA_SERVICE) as? CameraManager
        if (cameraManager == null) {
            result.success(null)
            return
        }
        try {
            val cameraId = cameraManager.cameraIdList.firstOrNull { id ->
                cameraManager.getCameraCharacteristics(id)
                    .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            }
            if (cameraId == null) {
                result.success(null)
                return
            }
            cameraManager.setTorchMode(cameraId, enabled)
            result.success(enabled)
        } catch (_: Throwable) {
            result.success(null)
        }
    }

    // region internals

    private fun deviceInfoMap(): Map<String, Any?> {
        val map = LinkedHashMap<String, Any?>()
        map["manufacturer"] = Build.MANUFACTURER
        map["brand"] = Build.BRAND
        map["model"] = Build.MODEL
        map["device"] = Build.DEVICE
        map["androidRelease"] = Build.VERSION.RELEASE
        map["sdkInt"] = Build.VERSION.SDK_INT
        map["securityPatch"] = Build.VERSION.SECURITY_PATCH
        map["buildId"] = Build.ID
        map["fingerprint"] = Build.FINGERPRINT
        map["abi"] = Build.SUPPORTED_ABIS.joinToString(", ")
        map["locale"] = java.util.Locale.getDefault().toLanguageTag()
        map["timezone"] = java.util.TimeZone.getDefault().id
        map["isEmulator"] = isProbablyEmulator()
        map["hasFlash"] = try {
            context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_FLASH)
        } catch (_: Throwable) {
            false
        }
        return map
    }

    private fun isProbablyEmulator(): Boolean {
        val fingerprint = Build.FINGERPRINT ?: ""
        val model = Build.MODEL ?: ""
        val product = Build.PRODUCT ?: ""
        return fingerprint.startsWith("generic") ||
            fingerprint.contains("emulator", ignoreCase = true) ||
            model.contains("google_sdk", ignoreCase = true) ||
            model.contains("Emulator", ignoreCase = true) ||
            model.contains("Android SDK built for", ignoreCase = true) ||
            (product.contains("sdk", ignoreCase = true) && fingerprint.contains("generic", ignoreCase = true))
    }

    private fun chargeCounterMah(): Int? = try {
        val bm = context.getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val counter = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_CHARGE_COUNTER)
        if (counter > 0) counter / 1000 else null
    } catch (_: Throwable) {
        null
    }

    /** Operator name needs no permission; it is the only telephony value we read. */
    private fun carrierName(): String? = try {
        val tm = context.getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        tm?.networkOperatorName?.takeIf { it.isNotBlank() }
    } catch (_: Throwable) {
        null
    }

    /**
     * Whether *this* app is allowed to install packages from unknown sources.
     * Android does not expose other apps' allowances, and the app never
     * requests REQUEST_INSTALL_PACKAGES, so "allowed" here means the user
     * toggled it manually.
     */
    private fun unknownSourcesAllowed(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.packageManager.canRequestPackageInstalls()
        } else {
            @Suppress("DEPRECATION")
            Settings.Secure.getInt(context.contentResolver, Settings.Secure.INSTALL_NON_MARKET_APPS, 0) == 1
        }
    } catch (_: Throwable) {
        false
    }

    private fun developerOptionsEnabled(): Boolean = try {
        Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
    } catch (_: Throwable) {
        false
    }

    private fun adbEnabled(): Boolean = try {
        Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) == 1
    } catch (_: Throwable) {
        false
    }

    // endregion
}
