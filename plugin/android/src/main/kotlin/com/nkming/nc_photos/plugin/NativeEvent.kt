package com.nkming.nc_photos.plugin

internal interface NativeEvent {
	fun getId(): String
	fun getData(): String? = null
}
