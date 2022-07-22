package com.nkming.nc_photos.plugin

import android.content.Context
import android.net.Uri
import com.nkming.nc_photos.plugin.image_processor.Rgba8Image
import com.nkming.nc_photos.plugin.image_processor.TfLiteHelper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class ImageLoaderChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/image_loader_method"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"loadUri" -> {
				try {
					loadUri(
						call.argument("fileUri")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("resizeMethod")!!,
						call.argument("isAllowSwapSide")!!,
						call.argument("shouldUpscale")!!,
						result
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
	 * @param result
	 */
	private fun loadUri(
		fileUri: String, maxWidth: Int, maxHeight: Int, resizeMethod: Int,
		isAllowSwapSide: Boolean, shouldUpscale: Boolean,
		result: MethodChannel.Result
	) {
		val image = BitmapUtil.loadImage(
			context, Uri.parse(fileUri), maxWidth, maxHeight,
			BitmapResizeMethod.values()[resizeMethod], isAllowSwapSide,
			shouldUpscale
		).use {
			Rgba8Image(TfLiteHelper.bitmapToRgba8Array(it), it.width, it.height)
		}
		result.success(image.toJson())
	}

	private val context = context
}
