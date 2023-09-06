package com.nkming.nc_photos.np_platform_lock

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformLockPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		handler = LockChannelHandler()
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger, LockChannelHandler.CHANNEL
		)
		methodChannel.setMethodCallHandler(handler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		handler.dismiss()
		methodChannel.setMethodCallHandler(null)
	}

	private lateinit var methodChannel: MethodChannel
	private lateinit var handler: LockChannelHandler
}
