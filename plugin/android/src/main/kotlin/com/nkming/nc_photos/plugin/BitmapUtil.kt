package com.nkming.nc_photos.plugin

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import java.io.InputStream

fun Bitmap.aspectRatio() = width / height.toFloat()

enum class BitmapResizeMethod {
	FIT,
	FILL,
}

interface BitmapUtil {
	companion object {
		fun loadImageFixed(
			context: Context, uri: Uri, targetW: Int, targetH: Int
		): Bitmap {
			val opt = loadImageBounds(context, uri)
			val subsample = calcBitmapSubsample(
				opt.outWidth, opt.outHeight, targetW, targetH,
				BitmapResizeMethod.FILL
			)
			if (subsample > 1) {
				logD(
					TAG,
					"Subsample image to fixed: $subsample ${opt.outWidth}x${opt.outHeight} -> ${targetW}x$targetH"
				)
			}
			val outOpt = BitmapFactory.Options().apply {
				inSampleSize = subsample
			}
			val bitmap = loadImage(context, uri, outOpt)
			if (subsample > 1) {
				logD(TAG, "Bitmap subsampled: ${bitmap.width}x${bitmap.height}")
			}
			return Bitmap.createScaledBitmap(bitmap, targetW, targetH, true)
		}

		/**
		 * Load a bitmap
		 *
		 * If @c resizeMethod == FIT, make sure the size of the bitmap can fit
		 * inside the bound defined by @c targetW and @c targetH, i.e.,
		 * bitmap.w <= @c targetW and bitmap.h <= @c targetH
		 *
		 * If @c resizeMethod == FILL, make sure the size of the bitmap can
		 * completely fill the bound defined by @c targetW and @c targetH, i.e.,
		 * bitmap.w >= @c targetW and bitmap.h >= @c targetH
		 *
		 * If bitmap is smaller than the bound and @c shouldUpscale == true, it
		 * will be upscaled
		 *
		 * @param context
		 * @param uri
		 * @param targetW
		 * @param targetH
		 * @param resizeMethod
		 * @param isAllowSwapSide
		 * @param shouldUpscale
		 * @return
		 */
		fun loadImage(
			context: Context,
			uri: Uri,
			targetW: Int,
			targetH: Int,
			resizeMethod: BitmapResizeMethod,
			isAllowSwapSide: Boolean = false,
			shouldUpscale: Boolean = true,
		): Bitmap {
			val opt = loadImageBounds(context, uri)
			val shouldSwapSide = isAllowSwapSide &&
					opt.outWidth != opt.outHeight &&
					(opt.outWidth >= opt.outHeight) != (targetW >= targetH)
			val dstW = if (shouldSwapSide) targetH else targetW
			val dstH = if (shouldSwapSide) targetW else targetH
			val subsample = calcBitmapSubsample(
				opt.outWidth, opt.outHeight, dstW, dstH, resizeMethod
			)
			if (subsample > 1) {
				logD(
					TAG,
					"Subsample image to ${resizeMethod.name}: $subsample ${opt.outWidth}x${opt.outHeight} -> ${dstW}x$dstH" +
							(if (shouldSwapSide) " (swapped)" else "")
				)
			}
			val outOpt = BitmapFactory.Options().apply {
				inSampleSize = subsample
			}
			val bitmap = loadImage(context, uri, outOpt)
			if (subsample > 1) {
				logD(TAG, "Bitmap subsampled: ${bitmap.width}x${bitmap.height}")
			}
			if (bitmap.width < dstW && bitmap.height < dstH && !shouldUpscale) {
				return bitmap
			}
			return when (resizeMethod) {
				BitmapResizeMethod.FIT -> Bitmap.createScaledBitmap(
					bitmap,
					minOf(dstW, (dstH * bitmap.aspectRatio()).toInt()),
					minOf(dstH, (dstW / bitmap.aspectRatio()).toInt()),
					true
				)

				BitmapResizeMethod.FILL -> Bitmap.createScaledBitmap(
					bitmap,
					maxOf(dstW, (dstH * bitmap.aspectRatio()).toInt()),
					maxOf(dstH, (dstW / bitmap.aspectRatio()).toInt()),
					true
				)
			}
		}

		private fun openUriInputStream(
			context: Context, uri: Uri
		): InputStream? {
			return if (UriUtil.isAssetUri(uri)) {
				context.assets.open(UriUtil.getAssetUriPath(uri))
			} else {
				context.contentResolver.openInputStream(uri)
			}
		}

		private fun loadImageBounds(
			context: Context, uri: Uri
		): BitmapFactory.Options {
			openUriInputStream(context, uri)!!.use {
				val opt = BitmapFactory.Options().apply {
					inJustDecodeBounds = true
				}
				BitmapFactory.decodeStream(it, null, opt)
				return opt
			}
		}

		private fun loadImage(
			context: Context, uri: Uri, opt: BitmapFactory.Options
		): Bitmap {
			openUriInputStream(context, uri)!!.use {
				return BitmapFactory.decodeStream(it, null, opt)!!
			}
		}

		private fun calcBitmapSubsample(
			originalW: Int,
			originalH: Int,
			targetW: Int,
			targetH: Int,
			resizeMethod: BitmapResizeMethod
		): Int {
			return when (resizeMethod) {
				BitmapResizeMethod.FIT -> maxOf(
					originalW / targetW,
					originalH / targetH
				)
				BitmapResizeMethod.FILL -> minOf(
					originalW / targetW,
					originalH / targetH
				)
			}
		}

		private const val TAG = "BitmapUtil"
	}
}
