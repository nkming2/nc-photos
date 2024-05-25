package com.nkming.nc_photos

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.annotation.NonNull
import com.nkming.nc_photos.np_android_core.UriUtil
import com.nkming.nc_photos.np_android_core.logE
import com.nkming.nc_photos.np_android_core.logI
import com.nkming.nc_photos.np_platform_image_processor.NpPlatformImageProcessorPlugin
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.net.URLEncoder

class MainActivity : FlutterFragmentActivity(), MethodChannel.MethodCallHandler {
	companion object {
		private const val METHOD_CHANNEL = "com.nkming.nc_photos/activity"

		private const val TAG = "MainActivity"
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		if (intent.action == NpPlatformImageProcessorPlugin.ACTION_SHOW_IMAGE_PROCESSOR_RESULT) {
			val route = getRouteFromImageProcessorResult(intent) ?: return
			logI(TAG, "Initial route: $route")
			_initialRoute = route
		}
	}

	override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			SelfSignedCertChannelHandler.CHANNEL
		).setMethodCallHandler(
			SelfSignedCertChannelHandler(this)
		)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			ShareChannelHandler.CHANNEL
		).setMethodCallHandler(
			ShareChannelHandler(this)
		)
		MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL
		).setMethodCallHandler(this)

		EventChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			DownloadEventCancelChannelHandler.CHANNEL
		).setStreamHandler(
			DownloadEventCancelChannelHandler(this)
		)
	}

	override fun onNewIntent(intent: Intent) {
		when (intent.action) {
			NpPlatformImageProcessorPlugin.ACTION_SHOW_IMAGE_PROCESSOR_RESULT -> {
				val route = getRouteFromImageProcessorResult(intent) ?: return
				logI(TAG, "Navigate to route: $route")
				flutterEngine?.navigationChannel?.pushRoute(route)
			}

			else -> {
				super.onNewIntent(intent)
			}
		}
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"consumeInitialRoute" -> {
				result.success(_initialRoute)
				_initialRoute = null
			}

			else -> result.notImplemented()
		}
	}

	private fun getRouteFromImageProcessorResult(intent: Intent): String? {
		val resultUri = intent.getParcelableExtra<Uri>(
			NpPlatformImageProcessorPlugin.EXTRA_IMAGE_RESULT_URI
		)
		if (resultUri == null) {
			logE(TAG, "Image result uri == null")
			return null
		}
		return if (resultUri.scheme?.startsWith("http") == true) {
			// remote uri
			val encodedUrl = URLEncoder.encode(resultUri.toString(), "utf-8")
			"/result-viewer?url=$encodedUrl"
		} else {
			val filename = UriUtil.resolveFilename(this, resultUri)?.let {
				URLEncoder.encode(it, Charsets.UTF_8.toString())
			}
			StringBuilder().apply {
				append("/enhanced-photo-browser?")
				if (filename != null) append("filename=$filename")
			}.toString()
		}
	}

	private var _initialRoute: String? = null
}
