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
		val imageProcessorHandler = ImageProcessorChannelHandler(
			flutterPluginBinding.applicationContext
		)
		imageProcessorEventChannel = EventChannel(
			flutterPluginBinding.binaryMessenger,
			ImageProcessorChannelHandler.EVENT_CHANNEL
		)
		imageProcessorEventChannel.setStreamHandler(imageProcessorHandler)
		imageProcessorMethodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			ImageProcessorChannelHandler.METHOD_CHANNEL
		)
		imageProcessorMethodChannel.setMethodCallHandler(imageProcessorHandler)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		imageProcessorEventChannel.setStreamHandler(null)
		imageProcessorMethodChannel.setMethodCallHandler(null)
	}

	private lateinit var imageProcessorMethodChannel: MethodChannel
	private lateinit var imageProcessorEventChannel: EventChannel
}
