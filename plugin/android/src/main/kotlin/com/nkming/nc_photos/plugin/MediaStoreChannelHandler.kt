package com.nkming.nc_photos.plugin

import android.app.Activity
import android.content.ContentUris
import android.content.Context
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/*
 * Save downloaded item on device
 *
 * Methods:
 * Write binary content to a file in the Download directory. Return the Uri to
 * the file
 * fun saveFileToDownload(content: ByteArray, filename: String, subDir: String?): String
 *
 * Return files under @c relativePath and its sub dirs
 * fun queryFiles(relativePath: String): List<Map>
 */
class MediaStoreChannelHandler(context: Context) :
	MethodChannel.MethodCallHandler, ActivityAware {
	companion object {
		const val METHOD_CHANNEL = "${K.LIB_ID}/media_store_method"

		private const val TAG = "MediaStoreChannelHandler"
	}

	override fun onAttachedToActivity(binding: ActivityPluginBinding) {
		activity = binding.activity
	}

	override fun onReattachedToActivityForConfigChanges(
		binding: ActivityPluginBinding
	) {
		activity = binding.activity
	}

	override fun onDetachedFromActivity() {
		activity = null
	}

	override fun onDetachedFromActivityForConfigChanges() {
		activity = null
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"saveFileToDownload" -> {
				try {
					saveFileToDownload(
						call.argument("content")!!, call.argument("filename")!!,
						call.argument("subDir"), result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			"copyFileToDownload" -> {
				try {
					copyFileToDownload(
						call.argument("fromFile")!!, call.argument("filename"),
						call.argument("subDir"), result
					)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			"queryFiles" -> {
				try {
					queryFiles(call.argument("relativePath")!!, result)
				} catch (e: Throwable) {
					result.error("systemException", e.message, null)
				}
			}

			else -> result.notImplemented()
		}
	}

	private fun saveFileToDownload(
		content: ByteArray, filename: String, subDir: String?,
		result: MethodChannel.Result
	) {
		try {
			val uri = MediaStoreUtil.saveFileToDownload(
				context, content, filename, subDir
			)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			activity?.let { PermissionUtil.requestWriteExternalStorage(it) }
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private fun copyFileToDownload(
		fromFile: String, filename: String?, subDir: String?,
		result: MethodChannel.Result
	) {
		try {
			val fromUri = inputToUri(fromFile)
			val uri = MediaStoreUtil.copyFileToDownload(
				context, fromUri, filename, subDir
			)
			result.success(uri.toString())
		} catch (e: PermissionException) {
			activity?.let { PermissionUtil.requestWriteExternalStorage(it) }
			result.error("permissionError", "Permission not granted", null)
		}
	}

	private fun queryFiles(relativePath: String, result: MethodChannel.Result) {
		if (!PermissionUtil.hasReadExternalStorage(context)) {
			activity?.let { PermissionUtil.requestReadExternalStorage(it) }
			result.error("permissionError", "Permission not granted", null)
			return
		}

		val pathColumnName: String
		val pathArg: String
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
			pathColumnName = MediaStore.Images.Media.RELATIVE_PATH
			pathArg = "${relativePath}/%"
		} else {
			@Suppress("Deprecation")
			pathColumnName = MediaStore.Images.Media.DATA
			pathArg = "%/${relativePath}/%"
		}
		val projection = arrayOf(
			MediaStore.Images.Media._ID,
			MediaStore.Images.Media.DATE_MODIFIED,
			MediaStore.Images.Media.MIME_TYPE,
			MediaStore.Images.Media.DATE_TAKEN,
			MediaStore.Images.Media.DISPLAY_NAME,
			pathColumnName
		)
		val selection = StringBuilder().apply {
			append("${MediaStore.Images.Media.MIME_TYPE} LIKE ?")
			append("AND $pathColumnName LIKE ?")
		}.toString()
		val selectionArgs = arrayOf("image/%", pathArg)
		val files = context.contentResolver.query(
			MediaStore.Images.Media.EXTERNAL_CONTENT_URI,
			projection, selection, selectionArgs, null
		)!!.use {
			val idColumn = it.getColumnIndexOrThrow(MediaStore.Images.Media._ID)
			val dateModifiedColumn =
				it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_MODIFIED)
			val mimeTypeColumn =
				it.getColumnIndexOrThrow(MediaStore.Images.Media.MIME_TYPE)
			val dateTakenColumn =
				it.getColumnIndexOrThrow(MediaStore.Images.Media.DATE_TAKEN)
			val displayNameColumn =
				it.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME)
			val pathColumn = it.getColumnIndexOrThrow(pathColumnName)
			val products = mutableListOf<Map<String, Any>>()
			while (it.moveToNext()) {
				val id = it.getLong(idColumn)
				val dateModified = it.getLong(dateModifiedColumn)
				val mimeType = it.getString(mimeTypeColumn)
				val dateTaken = it.getLong(dateTakenColumn)
				val displayName = it.getString(displayNameColumn)
				val path = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
					// RELATIVE_PATH
					"${it.getString(pathColumn).trimEnd('/')}/$displayName"
				} else {
					// DATA
					it.getString(pathColumn)
				}
				val contentUri = ContentUris.withAppendedId(
					MediaStore.Images.Media.EXTERNAL_CONTENT_URI, id
				)
				products.add(buildMap {
					put("uri", contentUri.toString())
					put("displayName", displayName)
					put("path", path)
					put("dateModified", dateModified * 1000)
					put("mimeType", mimeType)
					if (dateTaken != 0L) put("dateTaken", dateTaken)
				})
				Log.d(
					TAG,
					"[queryEnhancedPhotos] Found $displayName, path=$path, uri=$contentUri"
				)
			}
			products
		}
		Log.i(TAG, "[queryEnhancedPhotos] Found ${files.size} files")
		result.success(files)
	}

	private fun inputToUri(fromFile: String): Uri {
		val testUri = Uri.parse(fromFile)
		return if (testUri.scheme == null) {
			// is a file path
			Uri.fromFile(File(fromFile))
		} else {
			// is a uri
			Uri.parse(fromFile)
		}
	}

	private val context = context
	private var activity: Activity? = null
}
