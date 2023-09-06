package com.nkming.nc_photos.np_platform_message_relay

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NpPlatformMessageRelayPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		val handler = MessageRelayChannelHandler()
		eventChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			MessageRelayChannelHandler.EVENT_CHANNEL
		)
		eventChannel.setStreamHandler(handler)
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			MessageRelayChannelHandler.METHOD_CHANNEL
		)
		methodChannel.setMethodCallHandler(handler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		eventChannel.setStreamHandler(null)
		methodChannel.setMethodCallHandler(null)
	}

	private lateinit var eventChannel: EventChannel
	private lateinit var methodChannel: MethodChannel
}
