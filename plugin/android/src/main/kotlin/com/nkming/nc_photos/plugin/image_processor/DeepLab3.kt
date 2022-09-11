package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.content.res.AssetManager
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import com.nkming.nc_photos.plugin.use

/**
 * DeepLab is a state-of-art deep learning model for semantic image
 * segmentation, where the goal is to assign semantic labels (e.g., person, dog,
 * cat and so on) to every pixel in the input image
 *
 * See: https://github.com/tensorflow/models/tree/master/research/deeplab
 */
class DeepLab3Portrait(
	context: Context, maxWidth: Int, maxHeight: Int, radius: Int
) {
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
		val am = context.assets

		return inferNative(am, rgb8Image, width, height, radius).let {
			TfLiteHelper.rgb8ArrayToBitmap(it, width, height)
		}
	}

	private external fun inferNative(
		am: AssetManager, image: ByteArray, width: Int, height: Int, radius: Int
	): ByteArray

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val radius = radius
}

class DeepLab3ColorPop(
	context: Context, maxWidth: Int, maxHeight: Int, weight: Float
) {
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
		val am = context.assets

		return inferNative(am, rgb8Image, width, height, weight).let {
			TfLiteHelper.rgb8ArrayToBitmap(it, width, height)
		}
	}

	private external fun inferNative(
		am: AssetManager, image: ByteArray, width: Int, height: Int,
		weight: Float
	): ByteArray

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val weight = weight
}
