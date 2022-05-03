package com.nkming.nc_photos.plugin

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.content.FileProvider
import java.io.*

class MediaStoreCopyWriter(data: InputStream) {
	operator fun invoke(ostream: OutputStream) {
		data.copyTo(ostream)
	}

	private val data = data
}

interface MediaStoreUtil {
	companion object {
		/**
		 * Save the @c content as a file under the user Download dir
		 *
		 * @param context
		 * @param content
		 * @param filename Filename of the new file
		 * @param subDir
		 * @return Uri of the created file
		 */
		fun saveFileToDownload(
			context: Context, content: ByteArray, filename: String,
			subDir: String? = null
		): Uri {
			return ByteArrayInputStream(content).use {
				writeFileToDownload(
					context, MediaStoreCopyWriter(it)::invoke, filename, subDir
				)
			}
		}

		/**
		 * Copy a file from @c fromFilePath to the user Download dir
		 *
		 * @param context
		 * @param fromFile Path of the file to be copied
		 * @param filename Filename of the new file. If null, the same filename
		 * @param subDir
		 * will be used
		 * @return Uri of the created file
		 */
		fun copyFileToDownload(
			context: Context, fromFile: Uri, filename: String? = null,
			subDir: String? = null
		): Uri {
			return context.contentResolver.openInputStream(fromFile)!!.use {
				writeFileToDownload(
					context, MediaStoreCopyWriter(it)::invoke,
					filename ?: UriUtil.resolveFilename(context, fromFile)!!,
					subDir
				)
			}
		}

		fun writeFileToDownload(
			context: Context, writer: (OutputStream) -> Unit, filename: String,
			subDir: String? = null
		): Uri {
			return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				writeFileToDownload29(context, writer, filename, subDir)
			} else {
				writeFileToDownload0(context, writer, filename, subDir)
			}
		}

		@RequiresApi(Build.VERSION_CODES.Q)
		private fun writeFileToDownload29(
			context: Context, writer: (OutputStream) -> Unit, filename: String,
			subDir: String?
		): Uri {
			// Add a media item that other apps shouldn't see until the item is
			// fully written to the media store.
			val resolver = context.applicationContext.contentResolver

			// Find all audio files on the primary external storage device.
			val collection = MediaStore.Downloads.getContentUri(
				MediaStore.VOLUME_EXTERNAL_PRIMARY
			)
			val details = ContentValues().apply {
				put(MediaStore.Downloads.DISPLAY_NAME, filename)
				if (subDir != null) {
					put(
						MediaStore.Downloads.RELATIVE_PATH,
						"${Environment.DIRECTORY_DOWNLOADS}/$subDir"
					)
				}
			}

			val contentUri = resolver.insert(collection, details)

			resolver.openFileDescriptor(contentUri!!, "w", null).use { pfd ->
				// Write data into the pending audio file.
				BufferedOutputStream(
					FileOutputStream(pfd!!.fileDescriptor)
				).use { stream ->
					writer(stream)
				}
			}
			return contentUri
		}

		private fun writeFileToDownload0(
			context: Context, writer: (OutputStream) -> Unit, filename: String,
			subDir: String?
		): Uri {
			if (!PermissionUtil.hasWriteExternalStorage(context)) {
				throw PermissionException("Permission not granted")
			}

			@Suppress("Deprecation")
			val path = Environment.getExternalStoragePublicDirectory(
				Environment.DIRECTORY_DOWNLOADS
			)
			val prefix = if (subDir != null) "$subDir/" else ""
			var file = File(path, prefix + filename)
			val baseFilename = file.nameWithoutExtension
			var count = 1
			while (file.exists()) {
				file = File(
					path, prefix + "$baseFilename ($count).${file.extension}"
				)
				++count
			}
			file.parentFile?.mkdirs()
			BufferedOutputStream(FileOutputStream(file)).use { stream ->
				writer(stream)
			}

			val fileUri = Uri.fromFile(file)
			triggerMediaScan(context, fileUri)
			val contentUri = FileProvider.getUriForFile(
				context, "${context.packageName}.fileprovider", file
			)
			return contentUri
		}

		private fun triggerMediaScan(context: Context, uri: Uri) {
			val scanIntent = Intent().apply {
				@Suppress("Deprecation")
				action = Intent.ACTION_MEDIA_SCANNER_SCAN_FILE
				data = uri
			}
			context.sendBroadcast(scanIntent)
		}
	}
}
