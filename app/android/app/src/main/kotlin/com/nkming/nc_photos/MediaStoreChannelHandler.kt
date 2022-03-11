package com.nkming.nc_photos

import android.app.Activity
import android.content.ContentValues
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.*

/*
 * Save downloaded item on device
 *
 * Methods:
 * Write binary content to a file in the Download directory. Return the Uri to
 * the file
 * fun saveFileToDownload(fileName: String, content: ByteArray): String
 */
class MediaStoreChannelHandler(activity: Activity) :
	MethodChannel.MethodCallHandler {
	companion object {
		@JvmStatic
		val CHANNEL = "com.nkming.nc_photos/media_store"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"saveFileToDownload" -> try {
				saveFileToDownload(
					call.argument("fileName")!!,
					call.argument("content")!!,
					result
				)
			} catch (e: Throwable) {
				result.error("systemException", e.message, null)
			}
			"copyFileToDownload" -> try {
				copyFileToDownload(
					call.argument("toFileName")!!,
					call.argument("fromFilePath")!!,
					result
				)
			} catch (e: Throwable) {
				result.error("systemException", e.message, null)
			}
			else -> result.notImplemented()
		}
	}

	private fun saveFileToDownload(
		fileName: String, content: ByteArray, result: MethodChannel.Result
	) {
		val stream = ByteArrayInputStream(content)
		writeFileToDownload(fileName, stream, result)
	}

	private fun copyFileToDownload(
		toFileName: String, fromFilePath: String, result: MethodChannel.Result
	) {
		val file = File(fromFilePath)
		val stream = file.inputStream()
		writeFileToDownload(toFileName, stream, result)
	}

	private fun writeFileToDownload(
		fileName: String, data: InputStream, result: MethodChannel.Result
	) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			writeFileToDownload29(fileName, data, result)
		} else {
			writeFileToDownload0(fileName, data, result)
		}
	}

	@RequiresApi(Build.VERSION_CODES.Q)
	private fun writeFileToDownload29(
		fileName: String, data: InputStream, result: MethodChannel.Result
	) {
		// Add a media item that other apps shouldn't see until the item is
		// fully written to the media store.
		val resolver = _context.applicationContext.contentResolver

		// Find all audio files on the primary external storage device.
		val collection = MediaStore.Downloads.getContentUri(
			MediaStore.VOLUME_EXTERNAL_PRIMARY
		)
		val file = File(fileName)
		val details = ContentValues().apply {
			put(MediaStore.Downloads.DISPLAY_NAME, file.name)
			if (file.parent != null) {
				put(
					MediaStore.Downloads.RELATIVE_PATH,
					"${Environment.DIRECTORY_DOWNLOADS}/${file.parent}"
				)
			}
		}

		val contentUri = resolver.insert(collection, details)

		resolver.openFileDescriptor(contentUri!!, "w", null).use { pfd ->
			// Write data into the pending audio file.
			BufferedOutputStream(FileOutputStream(pfd!!.fileDescriptor)).use { stream ->
				data.copyTo(stream)
			}
		}
		result.success(contentUri.toString())
	}

	private fun writeFileToDownload0(
		fileName: String, data: InputStream, result: MethodChannel.Result
	) {
		if (!PermissionHandler.ensureWriteExternalStorage(_activity)) {
			result.error("permissionError", "Permission not granted", null)
			return
		}

		val path = Environment.getExternalStoragePublicDirectory(
			Environment.DIRECTORY_DOWNLOADS
		)
		var file = File(path, fileName)
		var count = 1
		while (file.exists()) {
			val f = File(fileName)
			file =
				File(path, "${f.nameWithoutExtension} ($count).${f.extension}")
			++count
		}
		file.parentFile?.mkdirs()
		BufferedOutputStream(FileOutputStream(file)).use { stream ->
			data.copyTo(stream)
		}

		val fileUri = Uri.fromFile(file)
		triggerMediaScan(fileUri)
		val contentUri = FileProvider.getUriForFile(
			_context, "com.nkming.nc_photos.plugin.fileprovider", file
		)
		result.success(contentUri.toString())
	}

	private fun triggerMediaScan(uri: Uri) {
		val scanIntent = Intent().apply {
			action = Intent.ACTION_MEDIA_SCANNER_SCAN_FILE
			data = uri
		}
		_context.sendBroadcast(scanIntent)
	}

	private val _activity = activity
	private val _context get() = _activity
}
