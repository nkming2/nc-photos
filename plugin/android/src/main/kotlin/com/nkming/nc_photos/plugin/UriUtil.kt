package com.nkming.nc_photos.plugin

import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import com.nkming.nc_photos.np_android_log.logI

interface UriUtil {
	companion object {
		fun resolveFilename(context: Context, uri: Uri): String? {
			return if (uri.scheme == "file") {
				uri.lastPathSegment!!
			} else {
				context.contentResolver.query(
					uri, arrayOf(MediaStore.MediaColumns.DISPLAY_NAME), null,
					null, null
				).use {
					if (it == null || !it.moveToFirst()) {
						logI(TAG, "Uri not found: $uri")
						null
					} else {
						it.getString(
							it.getColumnIndexOrThrow(
								MediaStore.MediaColumns.DISPLAY_NAME
							)
						)
					}
				}
			}
		}

		/**
		 * Asset URI is a non-standard Uri that points to an asset file.
		 *
		 * An asset URI is formatted as file:///android_asset/path/to/file
		 *
		 * @param uri
		 * @return
		 */
		fun isAssetUri(uri: Uri): Boolean {
			return uri.scheme == "file" && uri.path?.startsWith(
				"/android_asset/"
			) == true
		}

		fun getAssetUriPath(uri: Uri): String {
			return uri.path!!.substring("/android_asset/".length)
		}

		private const val TAG = "UriUtil"
	}
}
