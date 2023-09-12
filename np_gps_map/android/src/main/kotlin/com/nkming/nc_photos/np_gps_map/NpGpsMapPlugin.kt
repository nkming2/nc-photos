package com.nkming.nc_photos.np_gps_map

import androidx.annotation.NonNull
import com.google.android.gms.maps.MapsInitializer
import com.google.android.gms.maps.OnMapsSdkInitializedCallback
import com.nkming.nc_photos.np_android_core.logD
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodChannel

class NpGpsMapPlugin : FlutterPlugin {
	companion object {
		private const val TAG = "NpGpsMapPlugin"
	}

	override fun onAttachedToEngine(
		@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
	) {
		handler = GpsMapChannelHandler()
		methodChannel = MethodChannel(
			flutterPluginBinding.binaryMessenger,
			GpsMapChannelHandler.METHOD_CHANNEL
		)
		methodChannel.setMethodCallHandler(handler)

		MapsInitializer.initialize(
			flutterPluginBinding.applicationContext,
			MapsInitializer.Renderer.LATEST, mapCallback
		)
	}

	override fun onDetachedFromEngine(
		@NonNull binding: FlutterPlugin.FlutterPluginBinding
	) {
		methodChannel.setMethodCallHandler(null)
	}

	private lateinit var methodChannel: MethodChannel
	private lateinit var handler: GpsMapChannelHandler

	private val mapCallback = OnMapsSdkInitializedCallback {
		handler.isNewGMapsRenderer = when (it) {
			MapsInitializer.Renderer.LATEST -> {
				logD(TAG, "Using new map renderer")
				true
			}

			MapsInitializer.Renderer.LEGACY -> {
				logD(TAG, "Using legacy map renderer")
				false
			}
		}

	}
}
