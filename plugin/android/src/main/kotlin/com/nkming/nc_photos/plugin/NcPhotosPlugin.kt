package com.nkming.nc_photos.plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NcPhotosPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger, LockChannelHandler.CHANNEL
		)
		lockChannel.setMethodCallHandler(LockChannelHandler())

		notificationChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			NotificationChannelHandler.CHANNEL
		)
		notificationChannel.setMethodCallHandler(
			NotificationChannelHandler(
				flutterPluginBinding.applicationContext
			)
		)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannel.setMethodCallHandler(null)
		notificationChannel.setMethodCallHandler(null)
	}

	private lateinit var lockChannel: MethodChannel
	private lateinit var notificationChannel: MethodChannel
}
