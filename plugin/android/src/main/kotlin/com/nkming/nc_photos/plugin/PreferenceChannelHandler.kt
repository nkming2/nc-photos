package com.nkming.nc_photos.plugin

import android.content.Context
import android.content.SharedPreferences
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class PreferenceChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/preference_method"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"setBool" -> {
				try {
					setBool(
						call.argument("prefName")!!,
						call.argument("key")!!,
						call.argument("value")!!,
						result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}

			"getBool" -> {
				try {
					getBool(
						call.argument("prefName")!!,
						call.argument("key")!!,
						call.argument("defValue"),
						result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun setBool(
		prefName: String, key: String, value: Boolean,
		result: MethodChannel.Result
	) {
		openPref(prefName).run {
			edit().run {
				putBoolean(key, value)
			}.apply()
		}
		result.success(null)
	}

	private fun getBool(
		prefName: String, key: String, defValue: Boolean?,
		result: MethodChannel.Result
	) {
		val product = openPref(prefName).run {
			if (contains(key)) {
				getBoolean(key, false)
			} else {
				defValue
			}
		}
		result.success(product)
	}

	private fun openPref(prefName: String): SharedPreferences {
		return context.getSharedPreferences(prefName, Context.MODE_PRIVATE)
	}

	private val context = context
}
