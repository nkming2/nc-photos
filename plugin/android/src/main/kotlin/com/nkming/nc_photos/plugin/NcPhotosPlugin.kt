package com.nkming.nc_photos.plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NcPhotosPlugin : FlutterPlugin, ActivityAware {
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

		mediaStoreChannelHandler =
			MediaStoreChannelHandler(flutterPluginBinding.applicationContext)
		mediaStoreMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			MediaStoreChannelHandler.METHOD_CHANNEL
		)
		mediaStoreMethodChannel.setMethodCallHandler(mediaStoreChannelHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler.dismiss()
		lockChannel.setMethodCallHandler(null)
		notificationChannel.setMethodCallHandler(null)
		nativeEventChannel.setStreamHandler(null)
		nativeEventMethodChannel.setMethodCallHandler(null)
		mediaStoreMethodChannel.setMethodCallHandler(null)
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		mediaStoreChannelHandler.onAttachedToActivity(binding)
	}

	override fun onReattachedToActivityForConfigChanges(
		binding: ActivityPluginBinding
	) {
		mediaStoreChannelHandler.onReattachedToActivityForConfigChanges(binding)
	}

	override fun onDetachedFromActivity() {
		mediaStoreChannelHandler.onDetachedFromActivity()
	}

	override fun onDetachedFromActivityForConfigChanges() {
		mediaStoreChannelHandler.onDetachedFromActivityForConfigChanges()
	}

	private lateinit var lockChannel: MethodChannel
	private lateinit var notificationChannel: MethodChannel
	private lateinit var nativeEventChannel: EventChannel
	private lateinit var nativeEventMethodChannel: MethodChannel
	private lateinit var mediaStoreMethodChannel: MethodChannel

	private lateinit var lockChannelHandler: LockChannelHandler
	private lateinit var mediaStoreChannelHandler: MediaStoreChannelHandler
}
