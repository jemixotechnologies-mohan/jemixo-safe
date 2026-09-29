package com.jemixo.jemixo_safe

import android.Manifest
import android.content.ContentUris
import android.content.Context
import android.database.Cursor
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.os.StatFs
import android.provider.MediaStore
import android.util.Size
import android.webkit.MimeTypeMap
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.InputStream
import java.security.MessageDigest

/**
 * Storage inventory built entirely on MediaStore.
 *
 * Only the media permissions are needed: photos, videos, audio and everything
 * in Downloads are indexed by the platform, and that is where the space goes.
 * No all-files access, no directory walking.
 *
 * Every entry carries a content [uri] plus the absolute [path] when the index
 * discloses it, so open/share/delete can pick whichever the OS accepts.
 */
class StorageModule(private val context: Context) {

    private data class FileEntry(
        val id: Long,
        val uri: String,
        val path: String,
        val name: String,
        val size: Long,
        val modified: Long,
        val mimeType: String?,
        val width: Int? = null,
        val height: Int? = null,
    )

    // region access

    fun storageAccess(): Map<String, Any?> = mapOf(
        "media" to canReadMedia(),
        "sdkInt" to Build.VERSION.SDK_INT,
    )

    fun canReadMedia(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            BridgeUtil.hasPermission(context, Manifest.permission.READ_MEDIA_IMAGES) ||
                BridgeUtil.hasPermission(context, Manifest.permission.READ_MEDIA_VIDEO)
        } else {
            BridgeUtil.hasPermission(context, Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    } catch (_: Throwable) {
        false
    }

    // endregion

    fun getOverview(call: MethodCall, result: MethodChannel.Result) {
        try {
            val stat = StatFs(Environment.getDataDirectory().path)
            val total = stat.blockCountLong * stat.blockSizeLong
            val free = stat.availableBlocksLong * stat.blockSizeLong
            result.success(
                mapOf(
                    "totalBytes" to total,
                    "freeBytes" to free,
                    "usedBytes" to (total - free).coerceAtLeast(0L),
                    "usedFraction" to if (total > 0) (total - free).toDouble() / total else 0.0,
                )
            )
        } catch (t: Throwable) {
            result.error("STORAGE_OVERVIEW_FAILED", t.message, null)
        }
    }

    fun getCategoryBreakdown(call: MethodCall, result: MethodChannel.Result) {
        try {
            val categories = LinkedHashMap<String, Long>()
            if (canReadMedia()) {
                categories["Images"] = mediaStoreTotal("${FileCols.MIME_TYPE} LIKE ?", arrayOf("image/%"))
                categories["Videos"] = mediaStoreTotal("${FileCols.MIME_TYPE} LIKE ?", arrayOf("video/%"))
                categories["Audio"] = mediaStoreTotal("${FileCols.MIME_TYPE} LIKE ?", arrayOf("audio/%"))
                categories["Downloads"] = downloads().sumOf { it.size }
                categories["APK Files"] = downloads().filter { it.isApk }.sumOf { it.size } +
                    mediaStoreTotal("${FileCols.MIME_TYPE} = ?", arrayOf(APK_MIME))
                categories["Archives"] = downloads().filter { it.isArchive }.sumOf { it.size }
            }

            val stat = StatFs(Environment.getDataDirectory().path)
            val used = (stat.blockCountLong - stat.availableBlocksLong) * stat.blockSizeLong
            // APK and archive sizes are already inside Downloads; do not count twice.
            val known = (categories["Images"] ?: 0L) + (categories["Videos"] ?: 0L) +
                (categories["Audio"] ?: 0L) + (categories["Downloads"] ?: 0L)
            categories["Apps & system"] = (used - known).coerceAtLeast(0L)

            result.success(
                categories.filterValues { it > 0 }.map { (name, bytes) ->
                    mapOf("category" to name, "bytes" to bytes)
                }
            )
        } catch (t: Throwable) {
            result.error("STORAGE_CATEGORY_FAILED", t.message, null)
        }
    }

    fun findLargeFiles(call: MethodCall, result: MethodChannel.Result) {
        val minBytes = call.argument<Number>("minBytes")?.toLong() ?: 100L * 1024 * 1024
        val limit = call.argument<Number>("limit")?.toInt() ?: 200
        try {
            val entries = LinkedHashMap<String, FileEntry>()
            for (entry in queryFiles("${FileCols.SIZE} >= ?", arrayOf(minBytes.toString()), "${FileCols.SIZE} DESC", limit)) {
                entries[entry.key] = entry
            }
            for (entry in downloads().filter { it.size >= minBytes }) {
                entries.putIfAbsent(entry.key, entry)
            }
            result.success(
                entries.values.sortedByDescending { it.size }.take(limit).map { it.toMap() }
            )
        } catch (t: Throwable) {
            result.error("LARGE_FILE_SCAN_FAILED", t.message, null)
        }
    }

    fun findDuplicates(call: MethodCall, result: MethodChannel.Result) {
        val minBytes = call.argument<Number>("minBytes")?.toLong() ?: 64L * 1024
        val limitGroups = call.argument<Number>("limitGroups")?.toInt() ?: 80
        try {
            // Candidates: everything the index exposes above the size floor.
            val candidates = LinkedHashMap<String, FileEntry>()
            for (entry in queryFiles("${FileCols.SIZE} >= ?", arrayOf(minBytes.toString()), "${FileCols.SIZE} DESC", 20_000)) {
                candidates[entry.key] = entry
            }
            for (entry in downloads().filter { it.size >= minBytes }) {
                candidates.putIfAbsent(entry.key, entry)
            }

            // Three passes: bucket by size, then by a cheap 64 KB prefix hash,
            // then by full content hash. Only genuine candidates get read fully.
            val bySize = candidates.values.groupBy { it.size }.filterValues { it.size > 1 }
            val groups = ArrayList<Map<String, Any?>>()
            outer@ for ((size, sameSize) in bySize.entries.sortedByDescending { it.key }) {
                val byPrefix = sameSize.groupBy { hashOf(it.uri, PREFIX_BYTES) }
                    .filterKeys { it.isNotEmpty() }
                    .filterValues { it.size > 1 }
                for ((_, prefixGroup) in byPrefix) {
                    val byHash = prefixGroup.groupBy { hashOf(it.uri, Long.MAX_VALUE) }
                        .filterKeys { it.isNotEmpty() }
                        .filterValues { it.size > 1 }
                    for ((_, duplicates) in byHash) {
                        if (groups.size >= limitGroups) break@outer
                        val sorted = duplicates.sortedWith(compareBy({ it.path.length }, { it.name }))
                        groups.add(
                            mapOf(
                                "sizeBytes" to size,
                                "wastedBytes" to (sorted.size - 1) * size,
                                "files" to sorted.map { it.toMap() },
                            )
                        )
                    }
                }
            }
            result.success(groups)
        } catch (t: Throwable) {
            result.error("DUPLICATE_SCAN_FAILED", t.message, null)
        }
    }

    fun findScreenshots(call: MethodCall, result: MethodChannel.Result) {
        try {
            @Suppress("DEPRECATION")
            val rows = queryImages(
                selection = "${MediaStore.Images.Media.DATA} LIKE ? OR ${MediaStore.Images.Media.DATA} LIKE ? OR ${MediaStore.Images.Media.DISPLAY_NAME} LIKE ?",
                args = arrayOf("%/Screenshots/%", "%/Screenshot%", "Screenshot%"),
                limit = 2000,
            )
            result.success(rows.map { it.toMap() })
        } catch (t: Throwable) {
            result.error("SCREENSHOT_SCAN_FAILED", t.message, null)
        }
    }

    /**
     * Every indexed file under WhatsApp / WhatsApp Business media folders.
     * Both the Android 11+ location (Android/media/com.whatsapp/WhatsApp/Media)
     * and the legacy one (WhatsApp/Media) end in the same path segment, so two
     * patterns cover all versions. Documents are not indexed for apps holding
     * only the media permission, so they are simply absent.
     */
    fun findWhatsApp(call: MethodCall, result: MethodChannel.Result) {
        try {
            val rows = queryFiles(
                "${FileCols.DATA} LIKE ? OR ${FileCols.DATA} LIKE ?",
                arrayOf("%/WhatsApp/Media/%", "%/WhatsApp Business/Media/%"),
                "${FileCols.DATE_MODIFIED} DESC",
                40_000,
            )
            result.success(rows.map { it.toMap() })
        } catch (t: Throwable) {
            result.error("WHATSAPP_SCAN_FAILED", t.message, null)
        }
    }

    /** Most recent photos from the media library, for the similar-photo finder. */
    fun findImages(call: MethodCall, result: MethodChannel.Result) {
        val limit = call.argument<Number>("limit")?.toInt() ?: 300
        try {
            result.success(queryImages(null, null, limit).map { it.toMap() })
        } catch (t: Throwable) {
            result.error("IMAGE_SCAN_FAILED", t.message, null)
        }
    }

    fun getDownloads(call: MethodCall, result: MethodChannel.Result) {
        try {
            result.success(downloads().sortedByDescending { it.modified }.take(500).map { it.toMap() })
        } catch (t: Throwable) {
            result.error("DOWNLOAD_SCAN_FAILED", t.message, null)
        }
    }

    /**
     * Small JPEG thumbnail for an image, decoded with sampling so a 12 MP photo
     * never becomes a 48 MB bitmap. Returns null for anything not decodable.
     */
    fun getThumbnail(call: MethodCall, result: MethodChannel.Result) {
        val target = call.argument<String>("target")
        val size = (call.argument<Number>("size")?.toInt() ?: 128).coerceIn(16, 512)
        if (target.isNullOrBlank()) {
            result.error("BAD_ARGS", "target is required", null)
            return
        }
        try {
            val bitmap = loadThumbnail(target, size)
            if (bitmap == null) {
                result.success(null)
                return
            }
            val out = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.JPEG, 82, out)
            bitmap.recycle()
            result.success(out.toByteArray())
        } catch (_: Throwable) {
            result.success(null)
        }
    }

    /**
     * Deletes media by content URI (or by path, resolved through the index).
     *
     * Result: `deleted`, `failed`, `errors` (targets that could not be removed)
     * and `needsConsent` (content URIs the platform will only delete after the
     * user confirms through [MediaDeleteHelper]).
     */
    fun deleteFiles(call: MethodCall, result: MethodChannel.Result) {
        val targets = call.argument<List<String>>("paths") ?: emptyList()
        var deleted = 0
        val errors = ArrayList<String>()
        val needsConsent = ArrayList<String>()

        for (target in targets) {
            if (target.isBlank()) continue
            val uri = if (target.startsWith("content://")) Uri.parse(target) else mediaUriForPath(target)
            if (uri == null) {
                errors.add(target)
                continue
            }
            when (deleteContent(uri)) {
                DeleteOutcome.DELETED -> deleted++
                DeleteOutcome.NEEDS_CONSENT -> needsConsent.add(uri.toString())
                DeleteOutcome.FAILED -> errors.add(target)
            }
        }
        result.success(
            mapOf(
                "deleted" to deleted,
                "failed" to errors.size,
                "errors" to errors,
                "needsConsent" to needsConsent,
            )
        )
    }

    // region internals

    private enum class DeleteOutcome { DELETED, NEEDS_CONSENT, FAILED }

    private fun deleteContent(uri: Uri): DeleteOutcome = try {
        if (context.contentResolver.delete(uri, null, null) > 0) {
            DeleteOutcome.DELETED
        } else {
            DeleteOutcome.FAILED
        }
    } catch (_: SecurityException) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) DeleteOutcome.NEEDS_CONSENT else DeleteOutcome.FAILED
    } catch (_: Throwable) {
        DeleteOutcome.FAILED
    }

    private fun mediaUriForPath(path: String): Uri? = try {
        val base = MediaStore.Files.getContentUri("external")
        var found: Uri? = null
        @Suppress("DEPRECATION")
        query(
            base,
            arrayOf(FileCols._ID),
            "${FileCols.DATA} = ?",
            arrayOf(path),
        ) { cursor ->
            if (found == null) found = ContentUris.withAppendedId(base, cursor.getLong(0))
        }
        found
    } catch (_: Throwable) {
        null
    }

    private object FileCols {
        const val _ID = MediaStore.Files.FileColumns._ID
        const val DISPLAY_NAME = MediaStore.Files.FileColumns.DISPLAY_NAME
        const val SIZE = MediaStore.Files.FileColumns.SIZE
        const val DATE_MODIFIED = MediaStore.Files.FileColumns.DATE_MODIFIED
        const val MIME_TYPE = MediaStore.Files.FileColumns.MIME_TYPE

        @Suppress("DEPRECATION")
        const val DATA = MediaStore.Files.FileColumns.DATA
    }

    private val fileProjection = arrayOf(
        FileCols._ID,
        FileCols.DISPLAY_NAME,
        FileCols.SIZE,
        FileCols.DATE_MODIFIED,
        FileCols.MIME_TYPE,
        FileCols.DATA,
    )

    private fun readEntry(base: Uri, cursor: Cursor): FileEntry? {
        val id = cursor.getLong(0)
        val name = cursor.getString(1) ?: return null
        val size = cursor.getLong(2)
        if (size <= 0) return null
        val mime = cursor.getString(4)
        return FileEntry(
            id = id,
            uri = ContentUris.withAppendedId(base, id).toString(),
            path = cursor.getString(5) ?: "",
            name = name,
            size = size,
            modified = cursor.getLong(3) * 1000L,
            mimeType = if (mime.isNullOrBlank()) guessMime(name) else mime,
        )
    }

    /** Files collection: media of every kind plus what the app can see. */
    private fun queryFiles(
        selection: String?,
        args: Array<String>?,
        sortOrder: String,
        limit: Int,
    ): List<FileEntry> {
        val base = MediaStore.Files.getContentUri("external")
        val rows = ArrayList<FileEntry>()
        val guarded = if (selection == null) {
            "${FileCols.MIME_TYPE} IS NOT NULL"
        } else {
            "($selection) AND ${FileCols.MIME_TYPE} IS NOT NULL"
        }
        query(base, fileProjection, guarded, args, sortOrder, limit) { cursor ->
            readEntry(base, cursor)?.let { rows.add(it) }
        }
        return rows
    }

    private var downloadsCache: List<FileEntry>? = null
    private var downloadsCacheAt = 0L

    /** Downloads collection (API 29+) or the Download folder rows on older Android. */
    private fun downloads(): List<FileEntry> {
        val cached = downloadsCache
        if (cached != null && System.currentTimeMillis() - downloadsCacheAt < 5_000L) return cached
        val base = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            MediaStore.Downloads.EXTERNAL_CONTENT_URI
        } else {
            MediaStore.Files.getContentUri("external")
        }
        val selection = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) null else "${FileCols.DATA} LIKE ?"
        val args = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) null else arrayOf("%/Download/%")
        val rows = ArrayList<FileEntry>()
        query(base, fileProjection, selection, args, "${FileCols.DATE_MODIFIED} DESC", 2000) { cursor ->
            readEntry(base, cursor)?.let { rows.add(it) }
        }
        downloadsCache = rows
        downloadsCacheAt = System.currentTimeMillis()
        return rows
    }

    private fun queryImages(selection: String?, args: Array<String>?, limit: Int): List<FileEntry> {
        val base = MediaStore.Images.Media.EXTERNAL_CONTENT_URI
        @Suppress("DEPRECATION")
        val projection = arrayOf(
            MediaStore.Images.Media._ID,
            MediaStore.Images.Media.DISPLAY_NAME,
            MediaStore.Images.Media.SIZE,
            MediaStore.Images.Media.DATE_MODIFIED,
            MediaStore.Images.Media.MIME_TYPE,
            MediaStore.Images.Media.DATA,
            MediaStore.Images.Media.WIDTH,
            MediaStore.Images.Media.HEIGHT,
        )
        val rows = ArrayList<FileEntry>()
        query(base, projection, selection, args, "${MediaStore.Images.Media.DATE_MODIFIED} DESC", limit) { cursor ->
            val entry = readEntry(base, cursor) ?: return@query
            rows.add(
                entry.copy(
                    width = if (cursor.isNull(6)) null else cursor.getInt(6),
                    height = if (cursor.isNull(7)) null else cursor.getInt(7),
                )
            )
        }
        return rows
    }

    private fun mediaStoreTotal(selection: String, args: Array<String>): Long {
        var total = 0L
        query(
            MediaStore.Files.getContentUri("external"),
            arrayOf(FileCols.SIZE),
            "($selection) AND ${FileCols.SIZE} > 0",
            args,
        ) { cursor -> total += cursor.getLong(0) }
        return total
    }

    /**
     * ContentResolver query with a portable LIMIT: Android 11+ rejects LIMIT
     * inside the sort order and wants query args instead.
     */
    private fun query(
        uri: Uri,
        projection: Array<String>,
        selection: String?,
        args: Array<String>?,
        sortOrder: String? = null,
        limit: Int? = null,
        onRow: (Cursor) -> Unit,
    ) {
        try {
            val cursor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val bundle = Bundle().apply {
                    if (selection != null) putString(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION, selection)
                    if (args != null) putStringArray(android.content.ContentResolver.QUERY_ARG_SQL_SELECTION_ARGS, args)
                    if (sortOrder != null) putString(android.content.ContentResolver.QUERY_ARG_SQL_SORT_ORDER, sortOrder)
                    if (limit != null) putInt(android.content.ContentResolver.QUERY_ARG_LIMIT, limit)
                }
                context.contentResolver.query(uri, projection, bundle, null)
            } else {
                val order = if (sortOrder != null && limit != null) "$sortOrder LIMIT $limit" else sortOrder
                context.contentResolver.query(uri, projection, selection, args, order)
            }
            cursor?.use { c ->
                var count = 0
                while (c.moveToNext()) {
                    onRow(c)
                    count++
                    if (limit != null && count >= limit) break
                }
            }
        } catch (_: Throwable) {
            // Permission denied or provider unavailable — report partial data.
        }
    }

    /** SHA-256 of at most [limit] leading bytes; empty string on failure. */
    private fun hashOf(uri: String, limit: Long): String = try {
        val digest = MessageDigest.getInstance("SHA-256")
        openStream(uri)?.use { stream ->
            val buffer = ByteArray(64 * 1024)
            var remaining = limit
            while (remaining > 0) {
                val read = stream.read(buffer, 0, minOf(buffer.size.toLong(), remaining).toInt())
                if (read <= 0) break
                digest.update(buffer, 0, read)
                remaining -= read
            }
        } ?: return ""
        digest.digest().joinToString("") { byte -> "%02x".format(byte) }
    } catch (_: Throwable) {
        ""
    }

    private fun openStream(target: String): InputStream? = try {
        if (target.startsWith("content://")) {
            context.contentResolver.openInputStream(Uri.parse(target))
        } else {
            java.io.File(target).takeIf { it.exists() }?.inputStream()
        }
    } catch (_: Throwable) {
        null
    }

    private fun loadThumbnail(target: String, size: Int): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && target.startsWith("content://")) {
            try {
                return context.contentResolver.loadThumbnail(Uri.parse(target), Size(size, size), null)
            } catch (_: Throwable) {
                // Fall through to manual decoding.
            }
        }
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        openStream(target)?.use { BitmapFactory.decodeStream(it, null, bounds) } ?: return null
        if (bounds.outWidth <= 0 || bounds.outHeight <= 0) return null

        var sample = 1
        while (bounds.outWidth / (sample * 2) >= size && bounds.outHeight / (sample * 2) >= size) {
            sample *= 2
        }
        val options = BitmapFactory.Options().apply {
            inSampleSize = sample
            inPreferredConfig = Bitmap.Config.RGB_565
        }
        return openStream(target)?.use { BitmapFactory.decodeStream(it, null, options) }
    }

    private fun guessMime(name: String): String {
        val ext = name.substringAfterLast('.', "").lowercase()
        if (ext.isEmpty()) return "application/octet-stream"
        if (ext == "apk" || ext == "apks") return APK_MIME
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext) ?: "application/octet-stream"
    }

    private val FileEntry.key: String get() = if (path.isNotEmpty()) path else uri

    private val FileEntry.isApk: Boolean
        get() = mimeType == APK_MIME || name.endsWith(".apk", true) || name.endsWith(".apks", true)

    private val FileEntry.isArchive: Boolean
        get() = ZIP_EXTENSIONS.any { name.endsWith(it, true) }

    private fun FileEntry.toMap(): Map<String, Any?> = mapOf<String, Any?>(
        "path" to path,
        "uri" to uri,
        "name" to name,
        "sizeBytes" to size,
        "modified" to modified,
        "mimeType" to mimeType,
        "width" to width,
        "height" to height,
    )

    // endregion

    companion object {
        private const val PREFIX_BYTES = 64L * 1024
        private const val APK_MIME = "application/vnd.android.package-archive"
        private val ZIP_EXTENSIONS = listOf(".zip", ".rar", ".7z", ".tar", ".gz")
    }
}
