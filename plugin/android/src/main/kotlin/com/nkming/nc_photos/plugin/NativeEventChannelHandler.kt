package com.nkming.nc_photos.plugin

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeEventChannelHandler : MethodChannel.MethodCallHandler,
	EventChannel.StreamHandler {
	companion object {
		const val EVENT_CHANNEL = "${K.LIB_ID}/native_event"
		const val METHOD_CHANNEL = "${K.LIB_ID}/native_event_method"

		private val eventSinks = mutableMapOf<Int, EventChannel.EventSink>()
		private var nextId = 0
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"fire" -> {
				try {
					fire(
						call.argument("event")!!, call.argument("data"), result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}
		}
	}

	override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
		eventSinks[id] = events
	}

	override fun onCancel(arguments: Any?) {
		eventSinks.remove(id)
	}

	private fun fire(
		event: String, data: String?, result: MethodChannel.Result
	) {
		for (s in eventSinks.values) {
			s.success(buildMap {
				put("event", event)
				if (data != null) put("data", data)
			})
		}
		result.success(null)
	}

	private val id = nextId++
}
