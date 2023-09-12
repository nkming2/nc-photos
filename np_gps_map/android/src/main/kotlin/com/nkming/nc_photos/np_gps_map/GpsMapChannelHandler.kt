package com.nkming.nc_photos.np_gps_map

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class GpsMapChannelHandler : MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/gps_map_method"

		private const val TAG = "GpsMapChannelHandler"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"isNewGMapsRenderer" -> {
				result.success(isNewGMapsRenderer)
			}

			else -> {
				result.notImplemented()
			}
		}
	}

	var isNewGMapsRenderer = false
}
