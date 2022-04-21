package com.nkming.nc_photos.plugin

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import java.io.*

interface MediaStoreUtil {
	companion object {
		/**
		 * Save the @c content as a file under the user Download dir
		 *
		 * @param context
		 * @param filename Filename of the new file
		 * @param content
		 * @return Uri of the created file
		 */
		fun saveFileToDownload(
			context: Context, filename: String, content: ByteArray
		): Uri {
			val stream = ByteArrayInputStream(content)
			return writeFileToDownload(context, filename, stream)
		}

		/**
		 * Copy a file from @c fromFilePath to the user Download dir
		 *
		 * @param context
		 * @param toFilename Filename of the new file
		 * @param fromFilePath Path of the file to be copied
		 * @return Uri of the created file
		 */
		fun copyFileToDownload(
			context: Context, toFilename: String, fromFilePath: String
		): Uri {
			val file = File(fromFilePath)
			val stream = file.inputStream()
			return writeFileToDownload(context, toFilename, stream)
		}

		private fun writeFileToDownload(
			context: Context, filename: String, data: InputStream
		): Uri {
			return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
				writeFileToDownload29(context, filename, data)
			} else {
				writeFileToDownload0(context, filename, data)
			}
		}

		@RequiresApi(Build.VERSION_CODES.Q)
		private fun writeFileToDownload29(
			context: Context, filename: String, data: InputStream
		): Uri {
			// Add a media item that other apps shouldn't see until the item is
			// fully written to the media store.
			val resolver = context.applicationContext.contentResolver

			// Find all audio files on the primary external storage device.
			val collection = MediaStore.Downloads.getContentUri(
				MediaStore.VOLUME_EXTERNAL_PRIMARY
			)
			val file = File(filename)
			val details = ContentValues().apply {
				put(MediaStore.Downloads.DISPLAY_NAME, file.name)
				if (file.parent != null) {
					put(
						MediaStore.Downloads.RELATIVE_PATH,
						"${Environment.DIRECTORY_DOWNLOADS}/${file.parent}"
					)
				}
			}

			val contentUri = resolver.insert(collection, details)

			resolver.openFileDescriptor(contentUri!!, "w", null).use { pfd ->
				// Write data into the pending audio file.
				BufferedOutputStream(
					FileOutputStream(pfd!!.fileDescriptor)
				).use { stream ->
					data.copyTo(stream)
				}
			}
			return contentUri
		}

		private fun writeFileToDownload0(
			context: Context, filename: String, data: InputStream
		): Uri {
			if (ContextCompat.checkSelfPermission(
					context, Manifest.permission.WRITE_EXTERNAL_STORAGE
				) != PackageManager.PERMISSION_GRANTED
			) {
				throw PermissionException("Permission not granted")
			}

			@Suppress("Deprecation")
			val path = Environment.getExternalStoragePublicDirectory(
				Environment.DIRECTORY_DOWNLOADS
			)
			var file = File(path, filename)
			var count = 1
			while (file.exists()) {
				val f = File(filename)
				file = File(
					path,
					"${f.nameWithoutExtension} ($count).${f.extension}"
				)
				++count
			}
			file.parentFile?.mkdirs()
			BufferedOutputStream(FileOutputStream(file)).use { stream ->
				data.copyTo(stream)
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
