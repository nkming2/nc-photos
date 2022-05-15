package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.graphics.Bitmap
import android.net.Uri
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import com.nkming.nc_photos.plugin.logI
import org.tensorflow.lite.Interpreter
import java.nio.FloatBuffer
import java.nio.IntBuffer
import kotlin.math.pow

class ZeroDce(context: Context, maxWidth: Int, maxHeight: Int, iteration: Int) {
	companion object {
		private const val TAG = "ZeroDce"
		private const val MODEL = "zero_dce_lite_200x300_iter8_60.tflite"
		private const val WIDTH = 300
		private const val HEIGHT = 200
	}

	fun infer(imageUri: Uri): Bitmap {
		val alphaMaps = inferAlphaMaps(imageUri)
		return enhance(imageUri, alphaMaps, iteration)
	}

	private fun inferAlphaMaps(imageUri: Uri): Bitmap {
		val interpreter =
			Interpreter(TfLiteHelper.loadModelFromAsset(context, MODEL))
		interpreter.allocateTensors()

		logI(TAG, "Converting bitmap to input")
		val inputBitmap =
			BitmapUtil.loadImageFixed(context, imageUri, WIDTH, HEIGHT)
		val inputs = arrayOf(TfLiteHelper.bitmapToRgbFloatArray(inputBitmap))
		val outputs = mapOf(
			0 to FloatBuffer.allocate(inputs[0].capacity()),
			1 to FloatBuffer.allocate(inputs[0].capacity())
		)
		logI(TAG, "Inferring")
		interpreter.runForMultipleInputsOutputs(inputs, outputs)

		return TfLiteHelper.rgbFloatArrayToBitmap(
			outputs[1]!!, inputBitmap.width, inputBitmap.height
		)
	}

	private fun enhance(
		imageUri: Uri, alphaMaps: Bitmap, iteration: Int
	): Bitmap {
		logI(TAG, "Enhancing image, iteration: $iteration")
		// we can't work with FloatBuffer directly here as a FloatBuffer is way
		// too large to fit in Android's heap limit
		// downscale original to prevent OOM
		val width: Int
		val height: Int
		val imgBuf: IntBuffer
		BitmapUtil.loadImage(
			context, imageUri, maxWidth, maxHeight, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false
		).apply {
			width = this.width
			height = this.height
			imgBuf = IntBuffer.allocate(width * height)
			copyPixelsToBuffer(imgBuf)
			recycle()
		}
		imgBuf.rewind()

		// resize aMaps
		val filterBuf: IntBuffer
		Bitmap.createScaledBitmap(alphaMaps, width, height, true).apply {
			filterBuf = IntBuffer.allocate(width * height)
			copyPixelsToBuffer(filterBuf)
			recycle()
		}
		filterBuf.rewind()

		val src = imgBuf.array()
		val filter = filterBuf.array()
		for (i in src.indices) {
			var sr = (src[i] and 0xFF) / 255f
			var sg = (src[i] shr 8 and 0xFF) / 255f
			var sb = (src[i] shr 16 and 0xFF) / 255f
			val fr = (filter[i] and 0xFF) / 255f
			val fg = (filter[i] shr 8 and 0xFF) / 255f
			val fb = (filter[i] shr 16 and 0xFF) / 255f
			for (j in 0 until iteration) {
				sr += -fr * (sr.pow(2f) - sr)
				sg += -fg * (sg.pow(2f) - sg)
				sb += -fb * (sb.pow(2f) - sb)
			}
			src[i] = (0xFF shl 24) or
					((sr * 255).toInt().coerceIn(0, 255)) or
					((sg * 255).toInt().coerceIn(0, 255) shl 8) or
					((sb * 255).toInt().coerceIn(0, 255) shl 16)
		}
		return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
			.apply {
				copyPixelsFromBuffer(imgBuf)
			}
	}

	private val context = context
	private val maxWidth = maxWidth
	private val maxHeight = maxHeight
	private val iteration = iteration
}
