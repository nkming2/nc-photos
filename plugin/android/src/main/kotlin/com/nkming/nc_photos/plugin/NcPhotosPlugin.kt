package com.nkming.nc_photos.plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NcPhotosPlugin : FlutterPlugin {
	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler = LockChannelHandler()
		lockChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger, LockChannelHandler.CHANNEL
		)
		lockChannel.setMethodCallHandler(lockChannelHandler)

		notificationChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			NotificationChannelHandler.CHANNEL
		)
		notificationChannel.setMethodCallHandler(
			NotificationChannelHandler(
				flutterPluginBinding.applicationContext
			)
		)

		val nativeEventHandler = NativeEventChannelHandler()
		nativeEventChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			NativeEventChannelHandler.EVENT_CHANNEL
		)
		nativeEventChannel.setStreamHandler(nativeEventHandler)
		nativeEventMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			NativeEventChannelHandler.METHOD_CHANNEL
		)
		nativeEventMethodChannel.setMethodCallHandler(nativeEventHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler.dismiss()
		lockChannel.setMethodCallHandler(null)
		notificationChannel.setMethodCallHandler(null)
		nativeEventChannel.setStreamHandler(null)
		nativeEventMethodChannel.setMethodCallHandler(null)
	}

	private lateinit var lockChannel: MethodChannel
	private lateinit var notificationChannel: MethodChannel
	private lateinit var nativeEventChannel: EventChannel
	private lateinit var nativeEventMethodChannel: MethodChannel

	private lateinit var lockChannelHandler: LockChannelHandler
}
