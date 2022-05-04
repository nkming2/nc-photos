package com.nkming.nc_photos.plugin

import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NcPhotosPlugin : FlutterPlugin, ActivityAware,
	PluginRegistry.ActivityResultListener {
	companion object {
		const val ACTION_SHOW_IMAGE_PROCESSOR_RESULT =
			K.ACTION_SHOW_IMAGE_PROCESSOR_RESULT
		const val EXTRA_IMAGE_RESULT_URI = K.EXTRA_IMAGE_RESULT_URI

		private const val TAG = "NcPhotosPlugin"
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
		mediaStoreChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			MediaStoreChannelHandler.EVENT_CHANNEL
		)
		mediaStoreChannel.setStreamHandler(mediaStoreChannelHandler)
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
		pluginBinding = binding
		binding.addActivityResultListener(this)
	}

	override fun onReattachedToActivityForConfigChanges(
		binding: ActivityPluginBinding
	) {
		mediaStoreChannelHandler.onReattachedToActivityForConfigChanges(binding)
		pluginBinding = binding
		binding.addActivityResultListener(this)
	}

	override fun onDetachedFromActivity() {
		mediaStoreChannelHandler.onDetachedFromActivity()
		pluginBinding?.removeActivityResultListener(this)
	}

	override fun onDetachedFromActivityForConfigChanges() {
		mediaStoreChannelHandler.onDetachedFromActivityForConfigChanges()
		pluginBinding?.removeActivityResultListener(this)
	}

	override fun onActivityResult(
		requestCode: Int, resultCode: Int, data: Intent?
	): Boolean {
		return try {
			when (requestCode) {
				K.MEDIA_STORE_DELETE_REQUEST_CODE -> {
					mediaStoreChannelHandler.onActivityResult(
						requestCode, resultCode, data
					)
				}

				else -> false
			}
		} catch (e: Throwable) {
			Log.e(
				TAG, "Failed while onActivityResult, requestCode=$requestCode"
			)
			false
		}
	}

	private var pluginBinding: ActivityPluginBinding? = null

	private lateinit var lockChannel: MethodChannel
	private lateinit var notificationChannel: MethodChannel
	private lateinit var nativeEventChannel: EventChannel
	private lateinit var nativeEventMethodChannel: MethodChannel
	private lateinit var mediaStoreChannel: EventChannel
	private lateinit var mediaStoreMethodChannel: MethodChannel
	private lateinit var imageProcessorMethodChannel: MethodChannel
	private lateinit var contentUriMethodChannel: MethodChannel

	private lateinit var lockChannelHandler: LockChannelHandler
	private lateinit var mediaStoreChannelHandler: MediaStoreChannelHandler
}
