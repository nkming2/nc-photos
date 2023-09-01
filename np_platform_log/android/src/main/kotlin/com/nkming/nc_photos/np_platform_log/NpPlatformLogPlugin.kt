package com.nkming.nc_photos.np_platform_log

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformLogPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		val logcatChannelHandler = LogcatChannelHandler()
		logcatMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			LogcatChannelHandler.METHOD_CHANNEL
		)
		logcatMethodChannel.setMethodCallHandler(logcatChannelHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		logcatMethodChannel.setMethodCallHandler(null)
	}

	private lateinit var logcatMethodChannel: MethodChannel
}
