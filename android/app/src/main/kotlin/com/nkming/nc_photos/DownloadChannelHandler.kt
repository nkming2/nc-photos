package com.nkming.nc_photos

import android.app.Activity
import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Environment
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Download a file
 *
 * Methods:
 * Download a file at @a url. If @a shouldNotify is false, no progress
 * notifications would be shown
 * fun downloadUrl(url: String, headers: Map<String, String>?,
 * 		mimeType: String?, filename: String, shouldNotify: Boolean?): String
 */
class DownloadChannelHandler(activity: Activity) :
	MethodChannel.MethodCallHandler {
	companion object {
		@JvmStatic
		val CHANNEL = "com.nkming.nc_photos/download"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"downloadUrl" -> {
				try {
					downloadUrl(
						call.argument("url")!!,
						call.argument("headers"),
						call.argument("mimeType"),
						call.argument("filename")!!,
						call.argument("shouldNotify"),
						result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}
			else -> {
				result.notImplemented()
			}
		}
	}

	private fun downloadUrl(
		url: String,
		headers: Map<String, String>?,
		mimeType: String?,
		filename: String,
		shouldNotify: Boolean?,
		result: MethodChannel.Result
	) {
		if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
			if (!PermissionHandler.ensureWriteExternalStorage(_activity)) {
				result.error("permissionError", "Permission not granted", null)
				return
			}
		}

		val uri = Uri.parse(url)
		val req = DownloadManager.Request(uri).apply {
			setDestinationInExternalPublicDir(
				Environment.DIRECTORY_DOWNLOADS, filename
			)
			for (h in headers ?: mapOf()) {
				addRequestHeader(h.key, h.value)
			}
			if (mimeType != null) {
				setMimeType(mimeType)
			}
			setVisibleInDownloadsUi(true)
			setNotificationVisibility(
				if (shouldNotify == false) DownloadManager.Request.VISIBILITY_HIDDEN
				else DownloadManager.Request.VISIBILITY_VISIBLE
			)
			allowScanningByMediaScanner()
		}

		val id = _downloadManager.enqueue(req)
		result.success(id)
	}

	private val _activity = activity
	private val _context get() = _activity
	private val _downloadManager by lazy {
		_context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
	}
}
