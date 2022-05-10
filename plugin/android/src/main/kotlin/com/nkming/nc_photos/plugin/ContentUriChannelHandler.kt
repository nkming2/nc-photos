package com.nkming.nc_photos.plugin

import android.content.Context
import android.net.Uri
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException

class ContentUriChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/content_uri_method"

		private const val TAG = "ContentUriChannelHandler"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"readUri" -> {
				try {
					readUri(call.argument("uri")!!, result)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun readUri(uri: String, result: MethodChannel.Result) {
		val uriTyped = Uri.parse(uri)
		try {
			val bytes =
				context.contentResolver.openInputStream(uriTyped)!!.use {
					it.readBytes()
				}
			result.success(bytes)
		} catch (e: FileNotFoundException) {
			result.error("fileNotFoundException", e.toString(), null)
		}
	}

	private val context = context
}
