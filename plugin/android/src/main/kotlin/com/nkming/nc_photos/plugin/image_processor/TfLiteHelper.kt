package com.nkming.nc_photos.plugin.image_processor

import android.content.Context
import android.graphics.Bitmap
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.nio.FloatBuffer
import java.nio.IntBuffer
import java.nio.channels.FileChannel
import kotlin.math.abs

interface TfLiteHelper {
	companion object {
		/**
		 * Load a TFLite model from the assets dir
		 *
		 * @param context
		 * @param name Name of the model file
		 * @return
		 */
		fun loadModelFromAsset(context: Context, name: String): ByteBuffer {
			val fd = context.assets.openFd(name)
			val istream = FileInputStream(fd.fileDescriptor)
			val channel = istream.channel
			return channel.map(
				FileChannel.MapMode.READ_ONLY, fd.startOffset, fd.declaredLength
			)
		}

		/**
		 * Convert an ARGB_8888 Android bitmap to a float RGB buffer
		 *
		 * @param bitmap
		 * @return
		 */
		fun bitmapToRgbFloatArray(bitmap: Bitmap): FloatBuffer {
			val buffer = IntBuffer.allocate(bitmap.width * bitmap.height)
			bitmap.copyPixelsToBuffer(buffer)
			val input = FloatBuffer.allocate(bitmap.width * bitmap.height * 3)
			buffer.array().forEach {
				input.put((it and 0xFF) / 255.0f)
				input.put((it shr 8 and 0xFF) / 255.0f)
				input.put((it shr 16 and 0xFF) / 255.0f)
			}
			input.rewind()
			return input
		}

		/**
		 * Convert a float RGB buffer to an ARGB_8888 Android bitmap
		 *
		 * @param output
		 * @param width
		 * @param height
		 * @return
		 */
		fun rgbFloatArrayToBitmap(
			output: FloatBuffer, width: Int, height: Int
		): Bitmap {
			val buffer = IntBuffer.allocate(width * height)
			var i = 0
			var pixel = 0
			output.array().forEach {
				val value = (abs(it * 255f)).toInt().coerceIn(0, 255)
				when (i++) {
					0 -> {
						// A
						pixel = 0xFF shl 24
						// R
						pixel = pixel or value
					}
					1 -> {
						// G
						pixel = pixel or (value shl 8)
					}
					2 -> {
						// B
						pixel = pixel or (value shl 16)

						buffer.put(pixel)
						i = 0
					}
				}
			}
			buffer.rewind()
			val outputBitmap =
				Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
			outputBitmap.copyPixelsFromBuffer(buffer)
			return outputBitmap
		}
	}
}
