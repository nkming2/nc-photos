package com.nkming.nc_photos

import android.Manifest
import android.app.Activity
import android.content.ContentValues
import android.content.pm.PackageManager
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream

private const val PERMISSION_REQUEST_CODE = 11011

/*
 * Save downloaded item on device
 *
 * Methods:
 * Write binary content to a file in the Download directory
 * fun saveFileToDownload(fileName: String, content: ByteArray)
 */
class MediaStoreChannelHandler(activity: Activity)
		: MethodChannel.MethodCallHandler {
	companion object {
		@JvmStatic
		val CHANNEL = "com.nkming.nc_photos/media_store"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		if (call.method == "saveFileToDownload") {
			saveFileToDownload(call.argument<String>("fileName")!!,
					call.argument<ByteArray>("content")!!, result)
		} else {
			result.notImplemented()
		}
	}

	private fun saveFileToDownload(fileName: String, content: ByteArray,
			result: MethodChannel.Result) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			saveFileToDownload29(fileName, content, result)
		} else {
			saveFileToDownload0(fileName, content, result)
		}
	}

	@RequiresApi(Build.VERSION_CODES.Q)
	private fun saveFileToDownload29(fileName: String, content: ByteArray,
			result: MethodChannel.Result) {
		// Add a media item that other apps shouldn't see until the item is
		// fully written to the media store.
		val resolver = _context.applicationContext.contentResolver

		// Find all audio files on the primary external storage device.
		val collection = MediaStore.Downloads.getContentUri(
				MediaStore.VOLUME_EXTERNAL_PRIMARY)
		val details = ContentValues().apply {
			put(MediaStore.Downloads.DISPLAY_NAME, fileName)
		}

		val contentUri = resolver.insert(collection, details)

		resolver.openFileDescriptor(contentUri!!, "w", null).use { pfd ->
			// Write data into the pending audio file.
			BufferedOutputStream(FileOutputStream(pfd!!.fileDescriptor)).use {
				stream -> stream.write(content)
			}
		}
		result.success(null)
	}

	private fun saveFileToDownload0(fileName: String, content: ByteArray,
			result: MethodChannel.Result) {
		if (ContextCompat.checkSelfPermission(_activity,
						Manifest.permission.WRITE_EXTERNAL_STORAGE)
				!= PackageManager.PERMISSION_GRANTED) {
			ActivityCompat.requestPermissions(_activity,
					arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
					PERMISSION_REQUEST_CODE)
			result.error("permissionError", "Permission not granted", null)
			return
		}

		val path = Environment.getExternalStoragePublicDirectory(
				Environment.DIRECTORY_DOWNLOADS)
		var file = File(path, fileName)
		var count = 1
		while (file.exists()) {
			val f = File(fileName)
			file = File(path, "${f.nameWithoutExtension} ($count).${f.extension}")
			++count
		}
		BufferedOutputStream(FileOutputStream(file)).use {
			stream -> stream.write(content)
		}
		result.success(null)
	}

	private val _activity = activity
	private val _context get() = _activity
}
