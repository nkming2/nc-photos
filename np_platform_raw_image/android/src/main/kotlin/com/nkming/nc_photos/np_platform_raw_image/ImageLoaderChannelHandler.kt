package com.nkming.nc_photos.np_platform_raw_image

import android.content.Context
import android.net.Uri
import com.nkming.nc_photos.np_android_core.BitmapResizeMethod
import com.nkming.nc_photos.np_android_core.BitmapUtil
import com.nkming.nc_photos.np_android_core.Rgba8Image
import com.nkming.nc_photos.np_android_core.use
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

internal class ImageLoaderChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/image_loader_method"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"loadUri" -> {
				try {
					loadUri(
						call.argument("fileUri")!!, call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("resizeMethod")!!,
						call.argument("isAllowSwapSide")!!,
						call.argument("shouldUpscale")!!,
						call.argument("shouldFixOrientation")!!, result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}

			else -> result.notImplemented()
		}
	}

	/**
	 * Load and resize an image pointed by a uri
	 *
	 * @param fileUri
	 * @param maxWidth
	 * @param maxHeight
	 * @param resizeMethod
	 * @param isAllowSwapSide
	 * @param shouldUpscale
	 * @param shouldFixOrientation
	 * @param result
	 */
	private fun loadUri(
		fileUri: String, maxWidth: Int, maxHeight: Int, resizeMethod: Int,
		isAllowSwapSide: Boolean, shouldUpscale: Boolean,
		shouldFixOrientation: Boolean, result: MethodChannel.Result
	) {
		val image = BitmapUtil.loadImage(
			context, Uri.parse(fileUri), maxWidth, maxHeight,
			BitmapResizeMethod.values()[resizeMethod], isAllowSwapSide,
			shouldUpscale, shouldFixOrientation
		).use {
			Rgba8Image.fromBitmap(it)
		}
		result.success(image.toJson())
	}

	private val context = context
}
