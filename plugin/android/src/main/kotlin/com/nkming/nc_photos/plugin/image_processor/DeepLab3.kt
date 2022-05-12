package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.graphics.*
import android.net.Uri
import android.util.Log
import com.google.android.renderscript.Toolkit
import com.nkming.nc_photos.plugin.BitmapResizeMethod
import com.nkming.nc_photos.plugin.BitmapUtil
import com.nkming.nc_photos.plugin.transform
import org.tensorflow.lite.Interpreter
import java.io.File
import java.nio.ByteBuffer
import java.nio.FloatBuffer

/**
 * DeepLab is a state-of-art deep learning model for semantic image
 * segmentation, where the goal is to assign semantic labels (e.g., person, dog,
 * cat and so on) to every pixel in the input image
 *
 * See: https://github.com/tensorflow/models/tree/master/research/deeplab
 */
private class DeepLab3(context: Context) {
	companion object {
		private const val MODEL = "lite-model_mobilenetv2-dm05-coco_dr_1.tflite"
		const val WIDTH = 513
		const val HEIGHT = 513

		private const val TAG = "DeepLab3"
	}

	enum class Label(val value: Int) {
		BACKGROUND(0),
		AEROPLANE(1),
		BICYCLE(2),
		BIRD(3),
		BOAT(4),
		BOTTLE(5),
		BUS(6),
		CAR(7),
		CAT(8),
		CHAIR(9),
		COW(10),
		DINING_TABLE(11),
		DOG(12),
		HORSE(13),
		MOTORBIKE(14),
		PERSON(15),
		POTTED_PLANT(16),
		SHEEP(17),
		SOFA(18),
		TRAIN(19),
		TV(20),
	}

	fun infer(imageUri: Uri): ByteBuffer {
		val interpreter =
			Interpreter(TfLiteHelper.loadModelFromAsset(context, MODEL))
		interpreter.allocateTensors()

		Log.i(TAG, "Converting bitmap to input")
		val inputBitmap =
			BitmapUtil.loadImageFixed(context, imageUri, WIDTH, HEIGHT)
		val input = TfLiteHelper.bitmapToRgbFloatArray(inputBitmap)
		val output = FloatBuffer.allocate(WIDTH * HEIGHT * Label.values().size)
		Log.i(TAG, "Inferring")
		interpreter.run(input, output)
		return TfLiteHelper.argmax(output, WIDTH, HEIGHT, Label.values().size)
	}

	private val context = context
}

class DeepLab3Portrait(context: Context) {
	companion object {
		private const val RADIUS = 16
		private const val MAX_WIDTH = 2048
		private const val MAX_HEIGHT = 1536

		private const val TAG = "DeepLab3Portrait"
	}

	fun infer(imageUri: Uri): Bitmap {
		val segmentMap = deepLab.infer(imageUri).also {
			postProcessSegmentMap(it)
		}
		return enhance(imageUri, segmentMap, RADIUS)
	}

	/**
	 * Post-process the segment map.
	 *
	 * The resulting segment map will:
	 * 1. Contain only the most significant label (the one with the most pixel)
	 * 2. The label value set to 255
	 * 3. The background set to 0
	 *
	 * @param segmentMap
	 */
	private fun postProcessSegmentMap(segmentMap: ByteBuffer) {
		// keep only the largest segment
		val count = mutableMapOf<Byte, Int>()
		segmentMap.array().forEach {
			if (it != DeepLab3.Label.BACKGROUND.value.toByte()) {
				count[it] = (count[it] ?: 0) + 1
			}
		}
		val keep = count.maxByOrNull { it.value }?.key
		segmentMap.array().transform { if (it == keep) 0xFF.toByte() else 0 }
	}

	private fun enhance(
		imageUri: Uri, segmentMap: ByteBuffer, radius: Int
	): Bitmap {
		Log.i(TAG, "[enhance] Enhancing image")
		// downscale original to prevent OOM
		val orig = BitmapUtil.loadImage(
			context, imageUri, MAX_WIDTH, MAX_HEIGHT, BitmapResizeMethod.FIT,
			isAllowSwapSide = true, shouldUpscale = false
		)
		val bg = Toolkit.blur(orig, radius)

		var alpha = Bitmap.createBitmap(
			DeepLab3.WIDTH, DeepLab3.HEIGHT, Bitmap.Config.ALPHA_8
		)
		alpha.copyPixelsFromBuffer(segmentMap)
		alpha = Bitmap.createScaledBitmap(alpha, orig.width, orig.height, true)
		// blur the mask to smoothen the edge
		alpha = Toolkit.blur(alpha, 16)
		File(context.filesDir, "alpha.png").outputStream().use {
			alpha.compress(Bitmap.CompressFormat.PNG, 50, it)
		}

		val shader = ComposeShader(
			BitmapShader(orig, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
			BitmapShader(alpha, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP),
			PorterDuff.Mode.DST_ATOP
		)
		val paint = Paint().apply {
			setShader(shader)
		}
		Canvas(bg).apply {
			drawRect(0f, 0f, orig.width.toFloat(), orig.height.toFloat(), paint)
		}
		return bg
	}

	private val context = context
	private val deepLab = DeepLab3(context)
}
