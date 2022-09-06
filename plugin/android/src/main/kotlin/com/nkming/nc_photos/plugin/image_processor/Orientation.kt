package com.nkming.nc_photos.plugin.image_processor

import com.nkming.nc_photos.plugin.ImageFilter
import kotlin.math.abs

class Orientation(val degree: Int) : ImageFilter {
	override fun apply(rgba8: Rgba8Image): Rgba8Image {
		val data = applyNative(rgba8.pixel, rgba8.width, rgba8.height, degree)
		return Rgba8Image(
			data, if (abs(degree) == 90) rgba8.height else rgba8.width,
			if (abs(degree) == 90) rgba8.width else rgba8.height
		)
	}

	private external fun applyNative(
		rgba8: ByteArray, width: Int, height: Int, degree: Int
	): ByteArray
}
