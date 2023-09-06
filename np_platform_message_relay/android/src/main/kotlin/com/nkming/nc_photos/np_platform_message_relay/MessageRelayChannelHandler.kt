package com.nkming.nc_photos.np_platform_message_relay

import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class MessageRelayChannelHandler : MethodChannel.MethodCallHandler,
	EventChannel.StreamHandler {
	companion object {
		const val EVENT_CHANNEL = "${K.LIB_ID}/message_relay_event"
		const val METHOD_CHANNEL = "${K.LIB_ID}/message_relay_method"

		private val eventSinks = mutableMapOf<Int, EventChannel.EventSink>()
		private var nextId = 0
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"broadcast" -> {
				try {
					broadcast(
						call.argument("event")!!, call.argument("data"), result
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

	private fun broadcast(
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
