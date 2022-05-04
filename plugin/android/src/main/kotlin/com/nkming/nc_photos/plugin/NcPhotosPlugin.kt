package com.nkming.nc_photos.plugin

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NcPhotosPlugin : FlutterPlugin, ActivityAware {
	companion object {
		const val ACTION_SHOW_IMAGE_PROCESSOR_RESULT =
			K.ACTION_SHOW_IMAGE_PROCESSOR_RESULT
		const val EXTRA_IMAGE_RESULT_URI = K.EXTRA_IMAGE_RESULT_URI
	}

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

		imageProcessorMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			ImageProcessorChannelHandler.METHOD_CHANNEL
		)
		imageProcessorMethodChannel.setMethodCallHandler(
			ImageProcessorChannelHandler(
				flutterPluginBinding.applicationContext
			)
		)

		contentUriMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			ContentUriChannelHandler.METHOD_CHANNEL
		)
		contentUriMethodChannel.setMethodCallHandler(
			ContentUriChannelHandler(flutterPluginBinding.applicationContext)
		)
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
		imageProcessorMethodChannel.setMethodCallHandler(null)
		contentUriMethodChannel.setMethodCallHandler(null)
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
	private lateinit var imageProcessorMethodChannel: MethodChannel
	private lateinit var contentUriMethodChannel: MethodChannel

	private lateinit var lockChannelHandler: LockChannelHandler
	private lateinit var mediaStoreChannelHandler: MediaStoreChannelHandler
}
