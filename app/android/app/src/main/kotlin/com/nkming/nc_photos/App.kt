package com.nkming.nc_photos

import com.nkming.nc_photos.np_android_log.LogConfig
import io.flutter.BuildConfig
import io.flutter.app.FlutterApplication

class App : FlutterApplication() {
	override fun onCreate() {
		super.onCreate()
		LogConfig.isShowInfo = BuildConfig.DEBUG
		LogConfig.isShowDebug = BuildConfig.DEBUG
		LogConfig.isShowVerbose = BuildConfig.DEBUG
	}
}
