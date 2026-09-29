package com.jemixo.jemixo_safe

import android.app.Activity
import android.app.RecoverableSecurityException
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * User-consented media deletion for scoped storage.
 *
 * On Android 11+ the platform shows one confirmation for a batch
 * ([MediaStore.createDeleteRequest]). On Android 10 each file raises a
 * [RecoverableSecurityException] that carries its own consent intent, so the
 * caller re-runs the delete after each confirmation.
 */
class MediaDeleteHelper(private val activity: Activity) {

    private var pending: MethodChannel.Result? = null
    private var pendingCount = 0

    fun request(call: MethodCall, result: MethodChannel.Result) {
        val uris = (call.argument<List<String>>("uris") ?: emptyList())
            .filter { it.startsWith("content://") }
            .map { Uri.parse(it) }
        if (uris.isEmpty()) {
            result.success(mapOf("deleted" to 0, "cancelled" to false))
            return
        }
        if (pending != null) {
            result.error("BUSY", "A delete confirmation is already showing", null)
            return
        }

        try {
            val sender = when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R ->
                    MediaStore.createDeleteRequest(activity.contentResolver, uris).intentSender
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                    // Trigger the exception to obtain the consent intent for the first file.
                    try {
                        activity.contentResolver.delete(uris.first(), null, null)
                        result.success(mapOf("deleted" to 1, "cancelled" to false))
                        return
                    } catch (e: RecoverableSecurityException) {
                        e.userAction.actionIntent.intentSender
                    }
                }
                else -> {
                    result.success(mapOf("deleted" to 0, "cancelled" to false))
                    return
                }
            }
            pending = result
            pendingCount = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) uris.size else 1
            activity.startIntentSenderForResult(sender, REQUEST_CODE, null, 0, 0, 0)
        } catch (t: Throwable) {
            pending = null
            result.error("MEDIA_DELETE_FAILED", t.message, null)
        }
    }

    /** Returns true when the result belonged to this helper. */
    fun onActivityResult(requestCode: Int, resultCode: Int): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        pending = null
        val ok = resultCode == Activity.RESULT_OK
        result.success(
            mapOf(
                "deleted" to if (ok) pendingCount else 0,
                "cancelled" to !ok,
            )
        )
        return true
    }

    companion object {
        private const val REQUEST_CODE = 0x5AFE
    }
}
