package com.nkming.nc_photos.plugin

class LogConfig {
	companion object {
		var isShowInfo = true
		var isShowDebug = false
		var isShowVerbose = false
	}
}

fun logWtf(tag: String, msg: String) = android.util.Log.wtf(tag, msg)
fun logWtf(tag: String, msg: String, tr: Throwable) =
	android.util.Log.wtf(tag, msg, tr)

fun logE(tag: String, msg: String) = android.util.Log.e(tag, msg)
fun logE(tag: String, msg: String, tr: Throwable) =
	android.util.Log.e(tag, msg, tr)

fun logW(tag: String, msg: String) = android.util.Log.w(tag, msg)
fun logW(tag: String, msg: String, tr: Throwable) =
	android.util.Log.w(tag, msg, tr)

fun logI(tag: String, msg: String): Int {
	return if (LogConfig.isShowInfo) {
		android.util.Log.i(tag, msg)
	} else {
		-1
	}
}

fun logI(tag: String, msg: String, tr: Throwable): Int {
	return if (LogConfig.isShowInfo) {
		android.util.Log.i(tag, msg, tr)
	} else {
		-1
	}
}

fun logD(tag: String, msg: String): Int {
	return if (LogConfig.isShowDebug) {
		android.util.Log.d(tag, msg)
	} else {
		-1
	}
}

fun logD(tag: String, msg: String, tr: Throwable): Int {
	return if (LogConfig.isShowDebug) {
		android.util.Log.d(tag, msg, tr)
	} else {
		-1
	}
}

fun logV(tag: String, msg: String): Int {
	return if (LogConfig.isShowVerbose) {
		android.util.Log.v(tag, msg)
	} else {
		-1
	}
}

fun logV(tag: String, msg: String, tr: Throwable): Int {
	return if (LogConfig.isShowVerbose) {
		android.util.Log.v(tag, msg, tr)
	} else {
		-1
	}
}
