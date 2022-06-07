package com.nkming.nc_photos.plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LogcatChannelHandler : MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/logcat_method"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"dump" -> {
				try {
					dump(result)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun dump(result: MethodChannel.Result) {
		val logs = StringBuilder()
		val process = Runtime.getRuntime().exec("logcat -d")
		process.inputStream.bufferedReader().use {
			while (it.readLine()?.also(logs::appendLine) != null) {
			}
		}
		result.success(logs.toString())
	}
}
