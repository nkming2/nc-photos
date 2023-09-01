package com.nkming.nc_photos.np_platform_image_processor.processor

import androidx.exifinterface.media.ExifInterface
import com.nkming.nc_photos.np_android_core.logI

/**
 * Lossless rotation is done by modifying the EXIF orientation tag in such a way
 * that the viewer will rotate the image when displaying the image
 */
internal class LosslessRotator {
	companion object {
		const val TAG = "LosslessRotator"
	}

	/**
	 * Set the Orientation tag in @a dstExif according to the value in
	 * @a srcExif
	 *
	 * @param degree Either 0, 90, 180, -90 or -180
	 * @param srcExif ExifInterface of the src file
	 * @param dstExif ExifInterface of the dst file
	 */
	operator fun invoke(
		degree: Int, srcExif: ExifInterface, dstExif: ExifInterface
	) {
		assert(degree in listOf(0, 90, 180, -90, -180))
		val srcOrientation =
			srcExif.getAttributeInt(ExifInterface.TAG_ORIENTATION, 1)
		val dstOrientation = rotateExifOrientationValue(srcOrientation, degree)
		logI(TAG, "[invoke] $degree, $srcOrientation -> $dstOrientation")
		dstExif.setAttribute(
			ExifInterface.TAG_ORIENTATION, dstOrientation.toString()
		)
	}

	/**
	 * Return a new orientation representing the resulting value after rotating
	 * @a value
	 *
	 * @param value
	 * @param degree Either 0, 90, 180, -90 or -180
	 * @return
	 */
	private fun rotateExifOrientationValue(value: Int, degree: Int): Int {
		if (degree == 0) {
			return value
		}
		var newValue = rotateExifOrientationValue90Ccw(value)
		if (degree == 90) {
			return newValue
		}
		newValue = rotateExifOrientationValue90Ccw(newValue)
		if (degree == 180 || degree == -180) {
			return newValue
		}
		newValue = rotateExifOrientationValue90Ccw(newValue)
		return newValue
	}

	/**
	 * Return a new orientation representing the resulting value after rotating
	 * @a value for 90 degree CCW
	 *
	 * @param value
	 * @return
	 */
	private fun rotateExifOrientationValue90Ccw(value: Int): Int {
		return when (value) {
			0, 1 -> 8
			8 -> 3
			3 -> 6
			6 -> 1
			2 -> 7
			7 -> 4
			4 -> 5
			5 -> 2
			else -> throw IllegalArgumentException(
				"Invalid EXIF Orientation value: $value"
			)
		}
	}
}
