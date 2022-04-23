package com.nkming.nc_photos

import android.app.Activity
import com.nkming.nc_photos.plugin.MediaStoreUtil
import com.nkming.nc_photos.plugin.PermissionException
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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
			"saveFileToDownload" -> {
				try {
					saveFileToDownload(
						call.argument("fileName")!!,
						call.argument("content")!!,
						result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			"copyFileToDownload" -> {
				try {
					copyFileToDownload(
						call.argument("toFileName")!!,
						call.argument("fromFilePath")!!,
						result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun saveFileToDownload(
		fileName: String, content: ByteArray, result: MethodChannel.Result
	) {
		try {
			val uri =
				MediaStoreUtil.saveFileToDownload(_context, fileName, content)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			PermissionHandler.ensureWriteExternalStorage(_activity)
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private fun copyFileToDownload(
		toFileName: String, fromFilePath: String, result: MethodChannel.Result
	) {
		try {
			val uri = MediaStoreUtil.copyFileToDownload(
				_context, toFileName, fromFilePath
			)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			PermissionHandler.ensureWriteExternalStorage(_activity)
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private val _activity = activity
	private val _context get() = _activity
}
