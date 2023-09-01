package com.nkming.nc_photos.np_platform_image_processor

internal interface ImageProcessorEvent {
	fun getId(): String
}

internal class ImageProcessorUploadSuccessEvent : ImageProcessorEvent {
	companion object {
		const val id = "ImageProcessorUploadSuccessEvent"
	}

	override fun getId() = id
}
