package com.nkming.nc_photos.plugin

import android.app.PendingIntent
import android.os.Build
import java.net.HttpURLConnection

fun getPendingIntentFlagImmutable(): Int {
	return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
		PendingIntent.FLAG_IMMUTABLE else 0
}

fun getPendingIntentFlagMutable(): Int {
	return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
		PendingIntent.FLAG_MUTABLE else 0
}

inline fun <T> HttpURLConnection.use(block: (HttpURLConnection) -> T): T {
	try {
		connect()
		return block(this)
	} finally {
		disconnect()
	}
}
