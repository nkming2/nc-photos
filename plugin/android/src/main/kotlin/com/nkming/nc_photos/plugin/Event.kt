package com.nkming.nc_photos.plugin

import android.net.Uri

interface MessageEvent

data class ImageProcessorCompletedEvent(
	val image: Uri,
	val result: Uri,
) : MessageEvent

data class ImageProcessorFailedEvent(
	val image: Uri,
	val exception: Throwable,
) : MessageEvent
