package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil

class ZeroDce(context: Context, maxWidth: Int, maxHeight: Int, iteration: Int) {
	fun infer(imageUri: Uri): Bitmap {
		val width: Int
		val height: Int
		val rgb8Image = BitmapUtil.loadImage(
			context, imageUri, maxWidth, maxHeight, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false
		).let {
			width = it.width
			height = it.height
			val rgb8 = TfLiteHelper.bitmapToRgb8Array(it)
			it.recycle()
			rgb8
		}
		val am = context.assets

		return inferNative(am, rgb8Image, width, height, iteration).let {
			TfLiteHelper.rgb8ArrayToBitmap(it, width, height)
		}
	}

	private external fun inferNative(
		am: AssetManager, image: ByteArray, width: Int, height: Int,
		iteration: Int
	): ByteArray

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val iteration = iteration
}
