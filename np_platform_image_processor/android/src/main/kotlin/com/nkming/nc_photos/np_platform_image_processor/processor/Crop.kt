package com.nkming.nc_photos.np_platform_image_processor.processor

import com.nkming.nc_photos.np_android_core.Rgba8Image
import com.nkming.nc_photos.np_platform_image_processor.ImageFilter
import java.lang.Integer.max

internal class Crop(
	val top: Double, val left: Double, val bottom: Double, val right: Double
) : ImageFilter {
	override fun apply(rgba8: Rgba8Image): Rgba8Image {
		// prevent w/h == 0
		val width = max((rgba8.width * (right - left)).toInt(), 1)
		val height = max((rgba8.height * (bottom - top)).toInt(), 1)
		val top = (rgba8.height * top).toInt()
		val left = (rgba8.width * left).toInt()
		val data = applyNative(
			rgba8.pixel, rgba8.width, rgba8.height, top, left, width, height
		)
		return Rgba8Image(data, width, height)
	}

	private external fun applyNative(
		rgba8: ByteArray, width: Int, height: Int, top: Int, left: Int,
		dstWidth: Int, dstHeight: Int
	): ByteArray
}
