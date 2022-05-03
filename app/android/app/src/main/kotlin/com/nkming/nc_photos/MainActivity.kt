package com.nkming.nc_photos

import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
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

		EventChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			DownloadEventCancelChannelHandler.CHANNEL
		).setStreamHandler(
			DownloadEventCancelChannelHandler(this)
		)
	}
}
