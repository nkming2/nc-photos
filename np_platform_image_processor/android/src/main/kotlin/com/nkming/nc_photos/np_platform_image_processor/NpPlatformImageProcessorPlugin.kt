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
        const val EXTRA_IMAGE_RESULT_URI =
            K.EXTRA_IMAGE_RESULT_URI
    }

    override fun onAttachedToEngine(
        @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        imageProcessorMethodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            ImageProcessorChannelHandler.METHOD_CHANNEL
        )
        imageProcessorMethodChannel.setMethodCallHandler(
            ImageProcessorChannelHandler(
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
        imageProcessorMethodChannel.setMethodCallHandler(null)
        nativeEventChannel.setStreamHandler(null)
        nativeEventMethodChannel.setMethodCallHandler(null)
    }

    private lateinit var imageProcessorMethodChannel: MethodChannel
    private lateinit var nativeEventChannel: EventChannel
    private lateinit var nativeEventMethodChannel: MethodChannel
}
