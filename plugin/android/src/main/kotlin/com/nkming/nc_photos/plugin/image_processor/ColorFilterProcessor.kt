package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import com.nkming.nc_photos.plugin.ColorFilter
import com.nkming.nc_photos.plugin.use

class ColorFilterProcessor(
	context: Context, maxWidth: Int, maxHeight: Int,
	filters: List<Map<String, Any>>
) {
	companion object {
		const val TAG = "ColorFilterProcessor"
	}

	fun apply(imageUri: Uri): Bitmap {
		var img = BitmapUtil.loadImage(
			context, imageUri, maxWidth, maxHeight, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false
		).use {
			Rgba8Image(TfLiteHelper.bitmapToRgba8Array(it), it.width, it.height)
		}

		for (f in filters.map(ColorFilter::fromJson)) {
			img = f.apply(img)
		}
		return img.toBitmap()
	}

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val filters = filters
}
