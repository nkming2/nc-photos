package com.nkming.nc_photos.plugin.image_processor

import com.nkming.nc_photos.plugin.ColorFilter

class Saturation(val weight: Float) : ColorFilter {
	override fun apply(rgba8: Rgba8Image) = Rgba8Image(
		applyNative(rgba8.pixel, rgba8.width, rgba8.height, weight),
		rgba8.width, rgba8.height
	)

	private external fun applyNative(
		rgba8: ByteArray, width: Int, height: Int, weight: Float
	): ByteArray
}
