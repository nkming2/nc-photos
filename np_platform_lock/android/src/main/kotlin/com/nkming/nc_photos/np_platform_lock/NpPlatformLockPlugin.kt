package com.nkming.nc_photos.np_platform_lock

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformLockPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler = LockChannelHandler()
		lockChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger, LockChannelHandler.CHANNEL
		)
		lockChannel.setMethodCallHandler(lockChannelHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler.dismiss()
		lockChannel.setMethodCallHandler(null)
	}

	private lateinit var lockChannel: MethodChannel
	private lateinit var lockChannelHandler: LockChannelHandler
}
