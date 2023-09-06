package com.nkming.nc_photos.np_platform_raw_image

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformRawImagePlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		val handler =
			ImageLoaderChannelHandler(flutterPluginBinding.applicationContext)
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			ImageLoaderChannelHandler.METHOD_CHANNEL
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
