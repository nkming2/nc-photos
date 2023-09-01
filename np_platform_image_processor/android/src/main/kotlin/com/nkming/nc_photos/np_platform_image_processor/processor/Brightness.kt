package com.nkming.nc_photos.np_platform_image_processor.processor

import com.nkming.nc_photos.np_android_core.Rgba8Image
import com.nkming.nc_photos.np_platform_image_processor.ImageFilter

internal class Brightness(val weight: Float) : ImageFilter {
	override fun apply(rgba8: Rgba8Image) = Rgba8Image(
		applyNative(rgba8.pixel, rgba8.width, rgba8.height, weight),
		rgba8.width, rgba8.height
	)

	private external fun applyNative(
		rgba8: ByteArray, width: Int, height: Int, weight: Float
	): ByteArray
}
