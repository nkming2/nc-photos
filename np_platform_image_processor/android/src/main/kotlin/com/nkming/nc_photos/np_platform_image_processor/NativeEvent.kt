package com.nkming.nc_photos.np_platform_image_processor

// To be removed
internal interface NativeEvent {
    fun getId(): String
    fun getData(): String? = null
}

internal class ImageProcessorUploadSuccessEvent : NativeEvent {
    companion object {
        const val id = "ImageProcessorUploadSuccessEvent"
    }

    override fun getId() = id
}
