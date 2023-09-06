package com.nkming.nc_photos.np_platform_log

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformLogPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		val handler = LogcatChannelHandler()
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			LogcatChannelHandler.METHOD_CHANNEL
		)
		methodChannel.setMethodCallHandler(handler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		methodChannel.setMethodCallHandler(null)
	}

	private lateinit var methodChannel: MethodChannel
}
