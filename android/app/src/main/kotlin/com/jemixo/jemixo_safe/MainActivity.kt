package com.jemixo.jemixo_safe

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Main Flutter <-> Android bridge.
 *
 * Single [MethodChannel] (`com.jemixo.safe/native`) dispatching to focused
 * modules. Dart owns all interpretation; this layer only reports facts the
 * platform is willing to disclose.
 *
 * Anything that touches the file system or PackageManager at scale runs on a
 * background executor and posts its result back to the main thread, so a large
 * scan never blocks the UI or triggers an ANR.
 */
class MainActivity : FlutterActivity() {

    private lateinit var appScanner: AppScannerModule
    private lateinit var storage: StorageModule
    private lateinit var device: DeviceModule
    private lateinit var apkAnalyzer: ApkAnalyzerModule
    private lateinit var fileActions: FileActionModule
    private lateinit var mediaDelete: MediaDeleteHelper

    private var channel: MethodChannel? = null
    private val executor: ExecutorService = Executors.newFixedThreadPool(2)
    private val mainHandler = Handler(Looper.getMainLooper())

    /** Hand-off payload waiting for Dart to pull it after a cold start. */
    private var pendingShare: Map<String, Any?>? = null
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val context: Context = applicationContext

        appScanner = AppScannerModule(context)
        storage = StorageModule(context)
        device = DeviceModule(context)
        apkAnalyzer = ApkAnalyzerModule(context)
        fileActions = FileActionModule(context)
        mediaDelete = MediaDeleteHelper(this)

        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result -> handle(call, result) }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIncomingIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (mediaDelete.onActivityResult(requestCode, resultCode)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onDestroy() {
        executor.shutdownNow()
        super.onDestroy()
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Apps — package enumeration is slow, keep it off the UI thread.
            "getInstalledApps" -> background(result) { appScanner.getInstalledApps(call, it) }
            "getAppDetails" -> background(result) { appScanner.getAppDetails(call, it) }
            "getPackageVisibility" -> result.success(appScanner.packageVisibility())
            "openAppSettings" -> appScanner.openAppSettings(call, result)
            "openAppUninstall" -> appScanner.openAppUninstall(call, result)
            "openSystemSettings" -> appScanner.openSystemSettings(call, result)

            // Storage
            "getStorageOverview" -> storage.getOverview(call, result)
            "getStorageCategories" -> background(result) { storage.getCategoryBreakdown(call, it) }
            "findLargeFiles" -> background(result) { storage.findLargeFiles(call, it) }
            "findDuplicates" -> background(result) { storage.findDuplicates(call, it) }
            "findScreenshots" -> background(result) { storage.findScreenshots(call, it) }
            "findImages" -> background(result) { storage.findImages(call, it) }
            "getDownloads" -> background(result) { storage.getDownloads(call, it) }
            "getThumbnail" -> background(result) { storage.getThumbnail(call, it) }
            "deleteFiles" -> background(result) { storage.deleteFiles(call, it) }
            "requestMediaDelete" -> mediaDelete.request(call, result)
            "getStorageAccess" -> result.success(storage.storageAccess())

            // Device
            "getDeviceInfo" -> device.getDeviceInfo(call, result)
            "getBatteryInfo" -> device.getBatteryInfo(call, result)
            "getBatteryUsage" -> background(result) { device.getBatteryUsage(call, it) }
            "getNetworkInfo" -> device.getNetworkInfo(call, result)
            "getSensors" -> device.getSensors(call, result)
            "getMemoryInfo" -> device.getMemoryInfo(call, result)
            "getSecuritySettings" -> device.getSecuritySettings(call, result)
            "getSpecialAccess" -> background(result) { device.getSpecialAccess(call, it) }
            "copyToCache" -> {
                val uri = call.argument<String>("uri")
                background(result) {
                    val copied = if (uri.isNullOrBlank()) null else copyToCache(Uri.parse(uri), "shared-image")
                    it.success(copied?.absolutePath)
                }
            }
            "sampleSensor" -> device.sampleSensor(call, result)
            "openUsageAccessSettings" -> device.openUsageAccessSettings(call, result)
            "openBatteryOptimizationSettings" -> device.openBatteryOptimizationSettings(call, result)
            "setFlash" -> device.setFlash(call, result)

            // APK — zip parsing is I/O bound.
            "analyzeApk" -> background(result) { apkAnalyzer.analyzeApk(call, it) }

            // File actions
            "shareFile" -> fileActions.shareFile(call, result)
            "openFile" -> fileActions.openFile(call, result)
            "openFileLocation" -> fileActions.openLocation(call, result)
            "fileExists" -> background(result) { fileActions.fileExists(call, it) }

            // Hand-offs (share sheet, text selection, tile, notification)
            "getPendingShare" -> {
                dartReady = true
                result.success(pendingShare)
                pendingShare = null
            }

            // Install watcher + widget
            "setInstallWatch" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                background(result) {
                    InstallWatchWorker.setEnabled(applicationContext, enabled)
                    it.success(enabled)
                }
            }
            "isInstallWatchEnabled" -> background(result) {
                it.success(InstallWatchWorker.isEnabled(applicationContext))
            }
            "updateWidget" -> {
                SafetyWidgetProvider.update(
                    applicationContext,
                    call.argument<Number>("score")?.toInt(),
                    call.argument<String>("status") ?: "",
                    call.argument<String>("subtitle") ?: "",
                )
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Runs [block] on the executor. The wrapped result marshals back to the
     * main thread, which the Flutter messenger requires.
     */
    private fun background(
        result: MethodChannel.Result,
        block: (MethodChannel.Result) -> Unit,
    ) {
        val safe = MainThreadResult(result, mainHandler)
        try {
            executor.execute {
                try {
                    block(safe)
                } catch (t: Throwable) {
                    safe.error("NATIVE_ERROR", t.message ?: t.javaClass.simpleName, null)
                }
            }
        } catch (t: Throwable) {
            // Executor already shut down (activity finishing).
            safe.error("NATIVE_ERROR", t.message, null)
        }
    }

    // region hand-offs

    private fun handleIncomingIntent(intent: Intent?) {
        if (intent == null) return
        val payload: Map<String, Any?> = when (intent.action) {
            Intent.ACTION_SEND -> sharePayload(intent) ?: return
            Intent.ACTION_PROCESS_TEXT -> {
                val text = intent.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString()
                if (text.isNullOrBlank()) return
                mapOf("kind" to "text", "text" to text)
            }
            ACTION_CHECK_CLIPBOARD -> mapOf("kind" to "clipboard")
            ACTION_OPEN_PACKAGE -> {
                val packageName = intent.getStringExtra(EXTRA_PACKAGE) ?: return
                mapOf("kind" to "app", "packageName" to packageName)
            }
            else -> return
        }
        // Consume so a configuration change does not replay the hand-off.
        intent.action = Intent.ACTION_MAIN
        intent.removeExtra(Intent.EXTRA_TEXT)
        intent.removeExtra(Intent.EXTRA_STREAM)
        intent.removeExtra(Intent.EXTRA_PROCESS_TEXT)
        intent.removeExtra(EXTRA_PACKAGE)

        val live = channel
        if (dartReady && live != null) {
            mainHandler.post { live.invokeMethod("onShared", payload) }
        } else {
            pendingShare = payload
        }
    }

    private fun sharePayload(intent: Intent): Map<String, Any?>? {
        val type = intent.type ?: return null
        return if (type == "text/plain") {
            val text = intent.getStringExtra(Intent.EXTRA_TEXT)
                ?: intent.getCharSequenceExtra(Intent.EXTRA_TEXT)?.toString()
                ?: return null
            mapOf("kind" to "text", "text" to text)
        } else if (type.startsWith("image/")) {
            val uri = streamExtra(intent) ?: return null
            val copied = copyToCache(uri, "shared-image") ?: return null
            mapOf("kind" to "image", "path" to copied.absolutePath)
        } else {
            val uri = streamExtra(intent) ?: return null
            val copied = copyToCache(uri) ?: return null
            mapOf("kind" to "apk", "path" to copied.absolutePath, "name" to copied.name)
        }
    }

    @Suppress("DEPRECATION")
    private fun streamExtra(intent: Intent): Uri? = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    } catch (_: Throwable) {
        null
    }

    /** Copies a shared content URI into the app cache so it can be parsed by path. */
    private fun copyToCache(uri: Uri, fallback: String = "shared.apk"): File? = try {
        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val name = BridgeUtil.displayName(this, uri)?.takeIf { it.isNotBlank() } ?: fallback
        val target = File(dir, name.replace(Regex("[^A-Za-z0-9._-]"), "_"))
        contentResolver.openInputStream(uri)?.use { input ->
            target.outputStream().use { output -> input.copyTo(output) }
        } ?: return null
        target
    } catch (_: Throwable) {
        null
    }

    // endregion

    companion object {
        const val CHANNEL = "com.jemixo.safe/native"
        const val ACTION_CHECK_CLIPBOARD = "com.jemixo.safe.CHECK_CLIPBOARD"
        const val ACTION_OPEN_PACKAGE = "com.jemixo.safe.OPEN_PACKAGE"
        const val EXTRA_PACKAGE = "packageName"
    }
}

/** Forwards every callback onto the main looper. */
private class MainThreadResult(
    private val inner: MethodChannel.Result,
    private val handler: Handler,
) : MethodChannel.Result {
    private var delivered = false

    override fun success(result: Any?) = once { inner.success(result) }

    override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) =
        once { inner.error(errorCode, errorMessage, errorDetails) }

    override fun notImplemented() = once { inner.notImplemented() }

    private fun once(block: () -> Unit) {
        synchronized(this) {
            if (delivered) return
            delivered = true
        }
        handler.post(block)
    }
}
