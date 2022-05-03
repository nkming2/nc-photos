package com.nkming.nc_photos.plugin

import android.app.Activity
import android.content.Context
import android.net.Uri
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/*
 * Save downloaded item on device
 *
 * Methods:
 * Write binary content to a file in the Download directory. Return the Uri to
 * the file
 * fun saveFileToDownload(content: ByteArray, filename: String, subDir: String?): String
 */
class MediaStoreChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler, ActivityAware {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/media_store_method"

		private const val TAG = "MediaStoreChannelHandler"
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		activity = binding.activity
	}

	override fun onReattachedToActivityForConfigChanges(
		binding: ActivityPluginBinding
	) {
		activity = binding.activity
	}

	override fun onDetachedFromActivity() {
		activity = null
	}

	override fun onDetachedFromActivityForConfigChanges() {
		activity = null
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"saveFileToDownload" -> {
				try {
					saveFileToDownload(
						call.argument("content")!!, call.argument("filename")!!,
						call.argument("subDir"), result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			"copyFileToDownload" -> {
				try {
					copyFileToDownload(
						call.argument("fromFile")!!, call.argument("filename"),
						call.argument("subDir"), result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun saveFileToDownload(
		content: ByteArray, filename: String, subDir: String?,
		result: MethodChannel.Result
	) {
		try {
			val uri = MediaStoreUtil.saveFileToDownload(
				context, content, filename, subDir
			)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			activity?.let { PermissionUtil.requestWriteExternalStorage(it) }
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private fun copyFileToDownload(
		fromFile: String, filename: String?, subDir: String?,
		result: MethodChannel.Result
	) {
		try {
			val fromUri = inputToUri(fromFile)
			val uri = MediaStoreUtil.copyFileToDownload(
				context, fromUri, filename, subDir
			)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			activity?.let { PermissionUtil.requestWriteExternalStorage(it) }
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private fun inputToUri(fromFile: String): Uri {
		val testUri = Uri.parse(fromFile)
		return if (testUri.scheme == null) {
			// is a file path
			Uri.fromFile(File(fromFile))
		} else {
			// is a uri
			Uri.parse(fromFile)
		}
	}

	private val context = context
	private var activity: Activity? = null
}
