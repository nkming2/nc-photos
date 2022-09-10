package com.nkming.nc_photos.plugin

interface NativeEvent {
	fun getId(): String
	fun getData(): String? = null
}

class ImageProcessorUploadSuccessEvent : NativeEvent {
	companion object {
		const val id = "ImageProcessorUploadSuccessEvent"
	}

	override fun getId() = id
}
