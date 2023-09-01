package com.nkming.nc_photos.np_platform_image_processor

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class NativeEventChannelHandler : MethodChannel.MethodCallHandler,
	EventChannel.StreamHandler {
	companion object {
		const val EVENT_CHANNEL = "${K.LIB_ID}/native_event"
		const val METHOD_CHANNEL = "${K.LIB_ID}/native_event_method"

		/**
		 * Fire native events on the native side
		 */
		fun fire(eventObj: NativeEvent) {
			synchronized(eventSinks) {
				for (s in eventSinks.values) {
					s.success(buildMap {
						put("event", eventObj.getId())
						eventObj.getData()?.also { put("data", it) }
					})
				}
			}
		}

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
		synchronized(eventSinks) {
			eventSinks[id] = events
		}
	}

	override fun onCancel(arguments: Any?) {
		synchronized(eventSinks) {
			eventSinks.remove(id)
		}
	}

	private fun fire(
		event: String, data: String?, result: MethodChannel.Result
	) {
		synchronized(eventSinks) {
			for (s in eventSinks.values) {
				s.success(buildMap {
					put("event", event)
					if (data != null) put("data", data)
				})
			}
		}
		result.success(null)
	}

	private val id = nextId++
}
