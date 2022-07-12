package com.nkming.nc_photos.plugin.image_processor

import android.graphics.Bitmap
import java.nio.ByteBuffer

/**
 * Container of pixel data stored in RGBA format
 */
class Rgba8Image(val pixel: ByteArray, val width: Int, val height: Int) {
	companion object {
		fun fromJson(json: Map<String, Any>) = Rgba8Image(
			json["pixel"] as ByteArray, json["width"] as Int,
			json["height"] as Int
		)
	}

	fun toJson() = mapOf<String, Any>(
		"pixel" to pixel,
		"width" to width,
		"height" to height,
	)

	fun toBitmap(): Bitmap {
		return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
			.apply {
				copyPixelsFromBuffer(ByteBuffer.wrap(pixel))
			}
	}

	init {
		assert(pixel.size == width * height * 4)
	}
}
