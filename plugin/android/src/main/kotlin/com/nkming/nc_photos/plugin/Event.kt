package com.nkming.nc_photos.plugin

import android.net.Uri

interface MessageEvent

data class ImageProcessorCompletedEvent(
	val result: Uri,
) : MessageEvent

data class ImageProcessorFailedEvent(
	val exception: Throwable,
) : MessageEvent
