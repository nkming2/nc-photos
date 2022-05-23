package com.nkming.nc_photos.plugin

import android.content.Intent
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NcPhotosPlugin : FlutterPlugin, ActivityAware,
	PluginRegistry.ActivityResultListener,
	PluginRegistry.RequestPermissionsResultListener {
	companion object {
		init {
			System.loadLibrary("plugin")
		}

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

		permissionChannelHandler =
			PermissionChannelHandler(flutterPluginBinding.applicationContext)
		permissionChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			PermissionChannelHandler.EVENT_CHANNEL
		)
		permissionChannel.setStreamHandler(permissionChannelHandler)
		permissionMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			PermissionChannelHandler.METHOD_CHANNEL
		)
		permissionMethodChannel.setMethodCallHandler(permissionChannelHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		lockChannelHandler.dismiss()
		lockChannel.setMethodCallHandler(null)
		notificationChannel.setMethodCallHandler(null)
		nativeEventChannel.setStreamHandler(null)
		nativeEventMethodChannel.setMethodCallHandler(null)
		mediaStoreChannel.setStreamHandler(null)
		mediaStoreMethodChannel.setMethodCallHandler(null)
		imageProcessorMethodChannel.setMethodCallHandler(null)
		contentUriMethodChannel.setMethodCallHandler(null)
		permissionChannel.setStreamHandler(null)
		permissionMethodChannel.setMethodCallHandler(null)
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		mediaStoreChannelHandler.onAttachedToActivity(binding)
		permissionChannelHandler.onAttachedToActivity(binding)
		pluginBinding = binding
		binding.addActivityResultListener(this)
		binding.addRequestPermissionsResultListener(this)
	}

	override fun onReattachedToActivityForConfigChanges(
		binding: ActivityPluginBinding
	) {
		mediaStoreChannelHandler.onReattachedToActivityForConfigChanges(binding)
		permissionChannelHandler.onReattachedToActivityForConfigChanges(binding)
		pluginBinding = binding
		binding.addActivityResultListener(this)
		binding.addRequestPermissionsResultListener(this)
	}

	override fun onDetachedFromActivity() {
		mediaStoreChannelHandler.onDetachedFromActivity()
		permissionChannelHandler.onDetachedFromActivity()
		pluginBinding?.removeActivityResultListener(this)
		pluginBinding?.removeRequestPermissionsResultListener(this)
	}

	override fun onDetachedFromActivityForConfigChanges() {
		mediaStoreChannelHandler.onDetachedFromActivityForConfigChanges()
		permissionChannelHandler.onDetachedFromActivityForConfigChanges()
		pluginBinding?.removeActivityResultListener(this)
		pluginBinding?.removeRequestPermissionsResultListener(this)
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
			logE(TAG, "Failed while onActivityResult, requestCode=$requestCode")
			false
		}
	}

	override fun onRequestPermissionsResult(
		requestCode: Int, permissions: Array<String>, grantResults: IntArray
	): Boolean {
		return try {
			when (requestCode) {
				K.PERMISSION_REQUEST_CODE -> {
					permissionChannelHandler.onRequestPermissionsResult(
						requestCode, permissions, grantResults
					)
				}

				else -> false
			}
		} catch (e: Throwable) {
			logE(
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
	private lateinit var permissionChannel: EventChannel
	private lateinit var permissionMethodChannel: MethodChannel

	private lateinit var lockChannelHandler: LockChannelHandler
	private lateinit var mediaStoreChannelHandler: MediaStoreChannelHandler
	private lateinit var permissionChannelHandler: PermissionChannelHandler
}
