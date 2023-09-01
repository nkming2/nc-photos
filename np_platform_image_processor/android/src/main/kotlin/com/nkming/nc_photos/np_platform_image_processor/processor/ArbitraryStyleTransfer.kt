package com.nkming.nc_photos.np_platform_image_processor.processor

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.np_android_core.BitmapResizeMethod
import com.nkming.nc_photos.np_android_core.BitmapUtil
import com.nkming.nc_photos.np_android_core.logI
import com.nkming.nc_photos.np_android_core.use

internal class ArbitraryStyleTransfer(
	context: Context, maxWidth: Int, maxHeight: Int, styleUri: Uri,
	weight: Float
) {
	companion object {
		const val TAG = "ArbitraryStyleTransfer"
	}

	fun infer(imageUri: Uri): Bitmap {
		val width: Int
		val height: Int
		val rgb8Image = BitmapUtil.loadImage(
			context, imageUri, maxWidth, maxHeight, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false,
			shouldFixOrientation = true
		).use {
			width = it.width
			height = it.height
			TfLiteHelper.bitmapToRgb8Array(it)
		}
		val rgb8Style = BitmapUtil.loadImage(
			context, styleUri, 256, 256, BitmapResizeMethod.FILL,
			isAllowSwapSide = false, shouldUpscale = true
		).use {
			val styleBitmap = if (it.width != 256 || it.height != 256) {
				val x = (it.width - 256) / 2
				val y = (it.height - 256) / 2
				logI(
					TAG,
					"[infer] Resize and crop style image: ${it.width}x${it.height} -> 256x256 ($x, $y)"
				)
				// crop
				Bitmap.createBitmap(it, x, y, 256, 256)
			} else {
				it
			}
			styleBitmap.use {
				TfLiteHelper.bitmapToRgb8Array(styleBitmap)
			}
		}
		val am = context.assets

		return inferNative(
			am, rgb8Image, width, height, rgb8Style, weight
		).let {
			TfLiteHelper.rgb8ArrayToBitmap(it, width, height)
		}
	}

	private external fun inferNative(
		am: AssetManager, image: ByteArray, width: Int, height: Int,
		style: ByteArray, weight: Float
	): ByteArray

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val styleUri = styleUri
	private val weight = weight
}
