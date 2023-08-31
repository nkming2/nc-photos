package com.nkming.nc_photos.np_android_core

import android.graphics.Bitmap
import java.nio.ByteBuffer

/**
 * Container of pixel data stored in RGBA format
 */
class Rgba8Image(
    val pixel: ByteArray, val width: Int, val height: Int
) {
    companion object {
        fun fromJson(json: Map<String, Any>) = Rgba8Image(
            json["pixel"] as ByteArray,
            json["width"] as Int,
            json["height"] as Int
        )

        fun fromBitmap(src: Bitmap): Rgba8Image {
            assert(src.config == Bitmap.Config.ARGB_8888)
            val buffer = ByteBuffer.allocate(src.width * src.height * 4).also {
                src.copyPixelsToBuffer(it)
            }
            return Rgba8Image(buffer.array(), src.width, src.height)
        }
    }

    fun toJson() = mapOf<String, Any>(
        "pixel" to pixel,
        "width" to width,
        "height" to height,
    )

    fun toBitmap(): Bitmap {
        return Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
            .apply {
                copyPixelsFromBuffer(ByteBuffer.wrap(pixel))
            }
    }

    init {
        assert(pixel.size == width * height * 4)
    }
}
