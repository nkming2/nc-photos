package com.nkming.nc_photos.np_platform_image_processor

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class NpPlatformImageProcessorPlugin : FlutterPlugin {
	companion object {
		init {
			System.loadLibrary("np_platform_image_processor")
		}

		const val ACTION_SHOW_IMAGE_PROCESSOR_RESULT =
			K.ACTION_SHOW_IMAGE_PROCESSOR_RESULT
		const val EXTRA_IMAGE_RESULT_URI = K.EXTRA_IMAGE_RESULT_URI
	}

	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		val handler = ImageProcessorChannelHandler(
			flutterPluginBinding.applicationContext
		)
		eventChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			ImageProcessorChannelHandler.EVENT_CHANNEL
		)
		eventChannel.setStreamHandler(handler)
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			ImageProcessorChannelHandler.METHOD_CHANNEL
		)
		methodChannel.setMethodCallHandler(handler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		eventChannel.setStreamHandler(null)
		methodChannel.setMethodCallHandler(null)
	}

	private lateinit var methodChannel: MethodChannel
	private lateinit var eventChannel: EventChannel
}
