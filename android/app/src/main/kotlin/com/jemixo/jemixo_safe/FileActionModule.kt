package com.jemixo.jemixo_safe

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Environment
import android.provider.DocumentsContract
import android.webkit.MimeTypeMap
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * User-initiated actions: open, share and reveal a file through the platform
 * chooser. Raw `file://` URIs are never handed to other apps; everything goes
 * through the app's FileProvider or an existing content URI.
 */
class FileActionModule(private val context: Context) {

    fun shareFile(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("path")
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "path is required", null)
            return
        }
        try {
            val uri = uriFor(target)
            if (uri == null) {
                result.error("FILE_NOT_FOUND", "Unable to resolve file", null)
                return
            }
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = mimeOf(target)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(
                Intent.createChooser(intent, "Share file").apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            result.success(true)
        } catch (t: Throwable) {
            result.error("SHARE_FAILED", t.message, null)
        }
    }

    fun openFile(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("path")
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "path is required", null)
            return
        }
        try {
            val uri = uriFor(target)
            if (uri == null) {
                result.error("FILE_NOT_FOUND", "Unable to resolve file", null)
                return
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mimeOf(target))
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (t: Throwable) {
            result.error("OPEN_FAILED", t.message ?: "No app can open this file", null)
        }
    }

    /**
     * Reveals the folder that contains a file in the system Files app. The
     * DocumentsUI directory URI is the only portable way to do this; when the
     * device lacks it we fall back to opening the file itself.
     */
    fun openLocation(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("path")
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "path is required", null)
            return
        }
        val file = File(target)
        val parent = file.parentFile
        if (!target.startsWith("/") || parent == null || !parent.exists()) {
            result.success(false)
            return
        }
        try {
            val root = Environment.getExternalStorageDirectory().absolutePath
            val relative = parent.absolutePath.removePrefix(root).trimStart('/')
            val docUri = DocumentsContract.buildDocumentUri(
                "com.android.externalstorage.documents",
                "primary:$relative",
            )
            context.startActivity(
                Intent(Intent.ACTION_VIEW).apply {
                    setDataAndType(docUri, DocumentsContract.Document.MIME_TYPE_DIR)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
            )
            result.success(true)
        } catch (_: Throwable) {
            // No DocumentsUI handler; open the file instead so the user still
            // lands somewhere useful.
            openFile(call, result)
        }
    }

    fun fileExists(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("path")
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "path is required", null)
            return
        }
        result.success(
            if (target.startsWith("content://")) {
                try {
                    context.contentResolver.query(Uri.parse(target), null, null, null, null)?.use { cursor ->
                        cursor.count > 0
                    } ?: false
                } catch (_: Throwable) {
                    false
                }
            } else {
                File(target).exists()
            }
        )
    }

    private fun uriFor(target: String): Uri? = when {
        target.startsWith("content://") -> Uri.parse(target)
        else -> {
            val file = File(target)
            if (!file.exists()) {
                null
            } else {
                try {
                    FileProvider.getUriForFile(context, context.packageName + ".fileprovider", file)
                } catch (_: Throwable) {
                    null
                }
            }
        }
    }

    private fun mimeOf(target: String): String {
        if (target.startsWith("content://")) {
            return try {
                context.contentResolver.getType(Uri.parse(target)) ?: "*/*"
            } catch (_: Throwable) {
                "*/*"
            }
        }
        val ext = target.substringAfterLast('.', "").lowercase()
        if (ext.isEmpty()) return "*/*"
        return when (ext) {
            "apk", "apks" -> "application/vnd.android.package-archive"
            else -> MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "*/*"
        }
    }
}
