package com.nkming.nc_photos.plugin

import android.app.PendingIntent
import android.os.Build

fun getPendingIntentFlagImmutable(): Int {
	return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
		PendingIntent.FLAG_IMMUTABLE else 0
}

fun getPendingIntentFlagMutable(): Int {
	return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S)
		PendingIntent.FLAG_MUTABLE else 0
}
