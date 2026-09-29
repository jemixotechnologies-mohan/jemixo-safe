package com.jemixo.jemixo_safe

import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.Signature
import android.net.Uri
import android.provider.OpenableColumns
import androidx.core.content.ContextCompat
import java.security.MessageDigest

/**
 * Shared helpers for the Jemixo Safe native bridge.
 *
 * Everything here is intentionally defensive: Android throws a wide variety of
 * SecurityException / NameNotFoundException depending on OEM and API level, and a
 * security utility must degrade gracefully rather than crash the scan.
 */
object BridgeUtil {

    fun hasPermission(context: Context, permission: String): Boolean =
        ContextCompat.checkSelfPermission(context, permission) == PackageManager.PERMISSION_GRANTED

    /**
     * Launches a Settings action. Only actions that are scoped to one app take
     * a `package:` data URI; attaching one to a global screen (Wi-Fi, usage
     * access) makes several OEM Settings apps refuse the intent.
     */
    fun openSettings(
        context: Context,
        action: String,
        packageName: String? = null,
    ): Boolean = try {
        context.startActivity(
            Intent(action).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                if (packageName != null) {
                    data = Uri.fromParts("package", packageName, null)
                }
            }
        )
        true
    } catch (_: Throwable) {
        false
    }

    fun signatureSha256(signature: Signature): String = digestHex("SHA-256", signature.toByteArray())

    fun signatureMd5(signature: Signature): String = digestHex("MD5", signature.toByteArray())

    private fun digestHex(algorithm: String, bytes: ByteArray): String {
        val digest = MessageDigest.getInstance(algorithm).digest(bytes)
        val hex = StringBuilder(digest.size * 2)
        for (b in digest) {
            val v = b.toInt() and 0xFF
            hex.append("0123456789ABCDEF"[v ushr 4])
            hex.append("0123456789ABCDEF"[v and 0x0F])
        }
        return hex.toString()
    }

    /** Milliseconds since epoch, or null when the value is unavailable. */
    fun epochMillis(value: Long): Long? = if (value > 0L) value else null

    /** Display name for a content URI, when the provider exposes one. */
    fun displayName(context: Context, uri: Uri): String? = try {
        if (uri.scheme == "file") {
            uri.lastPathSegment
        } else {
            context.contentResolver
                .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    if (cursor.moveToFirst()) cursor.getString(0) else null
                } ?: uri.lastPathSegment
        }
    } catch (_: Throwable) {
        uri.lastPathSegment
    }
}
