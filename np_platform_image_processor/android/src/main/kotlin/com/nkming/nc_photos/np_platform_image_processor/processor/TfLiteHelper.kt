package com.nkming.nc_photos.np_platform_image_processor.processor

import android.graphics.Bitmap
import com.nkming.nc_photos.np_android_core.Rgba8Image
import java.nio.IntBuffer

internal interface TfLiteHelper {
    companion object {
        /**
         * Convert an ARGB_8888 Android bitmap to a RGB8 byte array
         *
         * @param bitmap
         * @return
         */
        fun bitmapToRgb8Array(bitmap: Bitmap): ByteArray {
            val buffer = IntBuffer.allocate(bitmap.width * bitmap.height)
            bitmap.copyPixelsToBuffer(buffer)
            val rgb8 = ByteArray(bitmap.width * bitmap.height * 3)
            buffer.array().forEachIndexed { i, it ->
                run {
                    rgb8[i * 3] = (it and 0xFF).toByte()
                    rgb8[i * 3 + 1] = (it shr 8 and 0xFF).toByte()
                    rgb8[i * 3 + 2] = (it shr 16 and 0xFF).toByte()
                }
            }
            return rgb8
        }

        /**
         * Convert an ARGB_8888 Android bitmap to a RGBA byte array
         *
         * @param bitmap
         * @return
         */
        fun bitmapToRgba8Array(bitmap: Bitmap): ByteArray {
            return Rgba8Image.fromBitmap(bitmap).pixel
        }

        /**
         * Convert a RGB8 byte array to an ARGB_8888 Android bitmap
         *
         * @param rgb8
         * @param width
         * @param height
         * @return
         */
        fun rgb8ArrayToBitmap(
            rgb8: ByteArray, width: Int, height: Int
        ): Bitmap {
            val buffer = IntBuffer.allocate(width * height)
            var i = 0
            var pixel = 0
            rgb8.forEach {
                val value = it.toInt() and 0xFF
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
