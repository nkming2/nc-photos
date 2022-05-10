package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import android.util.Log
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import org.tensorflow.lite.Interpreter
import java.nio.FloatBuffer
import kotlin.math.pow

class ZeroDce(context: Context) {
	companion object {
		private const val TAG = "ZeroDce"
		private const val MODEL = "zero_dce_lite_200x300_iter8_60.tflite"
		private const val WIDTH = 300
		private const val HEIGHT = 200
		private const val ITERATION = 8

		private const val MAX_WIDTH = 2048
		private const val MAX_HEIGHT = 1536
	}

	fun infer(imageUri: Uri): Bitmap {
		val alphaMaps = inferAlphaMaps(imageUri)
		return enhance(imageUri, alphaMaps, ITERATION)
	}

	private fun inferAlphaMaps(imageUri: Uri): Bitmap {
		val interpreter =
			Interpreter(TfLiteHelper.loadModelFromAsset(context, MODEL))
		interpreter.allocateTensors()

		Log.i(TAG, "Converting bitmap to input")
		val inputBitmap =
			BitmapUtil.loadImageFixed(context, imageUri, WIDTH, HEIGHT)
		val inputs = arrayOf(TfLiteHelper.bitmapToRgbFloatArray(inputBitmap))
		val outputs = mapOf(
			0 to FloatBuffer.allocate(inputs[0].capacity()),
			1 to FloatBuffer.allocate(inputs[0].capacity())
		)
		Log.i(TAG, "Inferring")
		interpreter.runForMultipleInputsOutputs(inputs, outputs)

		return TfLiteHelper.rgbFloatArrayToBitmap(
			outputs[1]!!, inputBitmap.width, inputBitmap.height
		)
	}

	private fun enhance(
		imageUri: Uri, alphaMaps: Bitmap, iteration: Int
	): Bitmap {
		Log.i(TAG, "Enhancing image, iteration: $iteration")
		// downscale original to prevent OOM
		val resized = BitmapUtil.loadImage(
			context, imageUri, MAX_WIDTH, MAX_HEIGHT, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false
		)
		// resize aMaps
		val resizedFilter = Bitmap.createScaledBitmap(
			alphaMaps, resized.width, resized.height, true
		)

		val imgBuf = TfLiteHelper.bitmapToRgbFloatArray(resized)
		val filterBuf = TfLiteHelper.bitmapToRgbFloatArray(resizedFilter)
		for (i in 0 until iteration) {
			val src = imgBuf.array()
			val filter = filterBuf.array()
			for (j in src.indices) {
				src[j] = src[j] + -filter[j] * (src[j].pow(2f) - src[j])
			}
		}
		return TfLiteHelper.rgbFloatArrayToBitmap(
			imgBuf, resized.width, resized.height
		)
	}

	private val context = context
}
