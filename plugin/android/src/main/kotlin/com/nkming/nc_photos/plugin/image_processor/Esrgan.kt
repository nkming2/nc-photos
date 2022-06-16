package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import com.nkming.nc_photos.plugin.use

class Esrgan(context: Context, maxWidth: Int, maxHeight: Int) {
	fun infer(imageUri: Uri): Bitmap {
		val width: Int
		val height: Int
		val rgb8Image = BitmapUtil.loadImage(
			context, imageUri, maxWidth / 4, maxHeight / 4,
			BitmapResizeMethod.FIT, isAllowSwapSide = true,
			shouldUpscale = false
		).use {
			width = it.width
			height = it.height
			TfLiteHelper.bitmapToRgb8Array(it)
		}
		val am = context.assets

		return inferNative(am, rgb8Image, width, height).let {
			TfLiteHelper.rgb8ArrayToBitmap(it, width * 4, height * 4)
		}
	}

	private external fun inferNative(
		am: AssetManager, image: ByteArray, width: Int, height: Int
	): ByteArray

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
}
