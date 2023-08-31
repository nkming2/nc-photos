package com.nkming.nc_photos.np_platform_image_processor

import android.net.Uri

internal interface MessageEvent

internal data class ImageProcessorCompletedEvent(
    val result: Uri,
) : MessageEvent

internal data class ImageProcessorFailedEvent(
    val exception: Throwable,
) : MessageEvent
