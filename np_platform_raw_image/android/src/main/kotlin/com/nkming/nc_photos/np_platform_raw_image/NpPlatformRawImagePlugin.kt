package com.nkming.nc_photos.np_platform_raw_image

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpPlatformRawImagePlugin : FlutterPlugin {
    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val imageLoaderChannelHandler =
            ImageLoaderChannelHandler(flutterPluginBinding.applicationContext)
        imageLoaderMethodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            ImageLoaderChannelHandler.METHOD_CHANNEL
        )
        imageLoaderMethodChannel.setMethodCallHandler(imageLoaderChannelHandler)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        imageLoaderMethodChannel.setMethodCallHandler(null)
    }

    private lateinit var imageLoaderMethodChannel: MethodChannel
}
