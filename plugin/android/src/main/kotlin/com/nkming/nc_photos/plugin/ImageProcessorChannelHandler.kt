package com.nkming.nc_photos.plugin

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.ContextCompat
import com.nkming.nc_photos.plugin.image_processor.*
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.Serializable

class ImageProcessorChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/image_processor_method"

		private const val TAG = "ImageProcessorChannelHandler"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"zeroDce" -> {
				try {
					zeroDce(
						call.argument("fileUrl")!!,
						call.argument("headers"),
						call.argument("filename")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("iteration")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			"deepLab3Portrait" -> {
				try {
					deepLab3Portrait(
						call.argument("fileUrl")!!,
						call.argument("headers"),
						call.argument("filename")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("radius")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			"esrgan" -> {
				try {
					esrgan(
						call.argument("fileUrl")!!,
						call.argument("headers"),
						call.argument("filename")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			"arbitraryStyleTransfer" -> {
				try {
					arbitraryStyleTransfer(
						call.argument("fileUrl")!!,
						call.argument("headers"),
						call.argument("filename")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("styleUri")!!,
						call.argument("weight")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			"colorFilter" -> {
				try {
					colorFilter(
						call.argument("fileUrl")!!,
						call.argument("headers"),
						call.argument("filename")!!,
						call.argument("maxWidth")!!,
						call.argument("maxHeight")!!,
						call.argument("filters")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			"filterPreview" -> {
				try {
					filterPreview(
						call.argument("rgba8")!!,
						call.argument("filters")!!,
						result
					)
				} catch (e: Throwable) {
					logE(TAG, "Uncaught exception", e)
					result.error("systemException", e.toString(), null)
				}
			}

			else -> result.notImplemented()
		}
	}

	override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
		eventSink = events
	}

	override fun onCancel(arguments: Any?) {
		eventSink = null
	}

	private fun zeroDce(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, iteration: Int,
		result: MethodChannel.Result
	) = method(
		fileUrl, headers, filename, maxWidth, maxHeight,
		ImageProcessorService.METHOD_ZERO_DCE, result, onIntent = {
			it.putExtra(ImageProcessorService.EXTRA_ITERATION, iteration)
		}
	)

	private fun deepLab3Portrait(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, radius: Int, result: MethodChannel.Result
	) = method(
		fileUrl, headers, filename, maxWidth, maxHeight,
		ImageProcessorService.METHOD_DEEP_LAP_PORTRAIT, result, onIntent = {
			it.putExtra(ImageProcessorService.EXTRA_RADIUS, radius)
		}
	)

	private fun esrgan(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, result: MethodChannel.Result
	) = method(
		fileUrl, headers, filename, maxWidth, maxHeight,
		ImageProcessorService.METHOD_ESRGAN, result
	)

	private fun arbitraryStyleTransfer(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, styleUri: String, weight: Float,
		result: MethodChannel.Result
	) = method(
		fileUrl, headers, filename, maxWidth, maxHeight,
		ImageProcessorService.METHOD_ARBITRARY_STYLE_TRANSFER, result,
		onIntent = {
			it.putExtra(
				ImageProcessorService.EXTRA_STYLE_URI, Uri.parse(styleUri)
			)
			it.putExtra(ImageProcessorService.EXTRA_WEIGHT, weight)
		}
	)

	private fun colorFilter(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, filters: List<Map<String, Any>>,
		result: MethodChannel.Result
	) {
		// convert to serializable
		val l = arrayListOf<Serializable>()
		filters.mapTo(l, { HashMap(it) })
		method(
			fileUrl, headers, filename, maxWidth, maxHeight,
			ImageProcessorService.METHOD_COLOR_FILTER, result,
			onIntent = {
				it.putExtra(ImageProcessorService.EXTRA_FILTERS, l)
			}
		)
	}

	private fun filterPreview(
		rgba8: Map<String, Any>, filters: List<Map<String, Any>>,
		result: MethodChannel.Result
	) {
		var img = Rgba8Image.fromJson(rgba8)
		for (f in filters.map(ColorFilter::fromJson)) {
			img = f.apply(img)
		}
		result.success(img.toJson())
	}

	private fun method(
		fileUrl: String, headers: Map<String, String>?, filename: String,
		maxWidth: Int, maxHeight: Int, method: String,
		result: MethodChannel.Result, onIntent: ((Intent) -> Unit)? = null
	) {
		val intent = Intent(context, ImageProcessorService::class.java).apply {
			putExtra(ImageProcessorService.EXTRA_METHOD, method)
			putExtra(ImageProcessorService.EXTRA_FILE_URL, fileUrl)
			putExtra(
				ImageProcessorService.EXTRA_HEADERS,
				headers?.let { HashMap(it) })
			putExtra(ImageProcessorService.EXTRA_FILENAME, filename)
			putExtra(ImageProcessorService.EXTRA_MAX_WIDTH, maxWidth)
			putExtra(ImageProcessorService.EXTRA_MAX_HEIGHT, maxHeight)
			onIntent?.invoke(this)
		}
		ContextCompat.startForegroundService(context, intent)
		result.success(null)
	}

	private val context = context
	private var eventSink: EventChannel.EventSink? = null
}

interface ColorFilter {
	companion object {
		fun fromJson(json: Map<String, Any>): ColorFilter {
			return when (json["type"]) {
				"brightness" -> Brightness((json["weight"] as Double).toFloat())
				"contrast" -> Contrast((json["weight"] as Double).toFloat())
				"whitePoint" -> WhitePoint((json["weight"] as Double).toFloat())
				"blackPoint" -> BlackPoint((json["weight"] as Double).toFloat())
				"saturation" -> Saturation((json["weight"] as Double).toFloat())
				"warmth" -> Warmth((json["weight"] as Double).toFloat())
				"tint" -> Tint((json["weight"] as Double).toFloat())
				else -> throw IllegalArgumentException(
					"Unknown type: ${json["type"]}"
				)
			}
		}
	}

	fun apply(rgba8: Rgba8Image): Rgba8Image
}
