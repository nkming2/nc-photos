package com.nkming.nc_photos.plugin

import android.content.Context
import android.net.Uri
import android.provider.MediaStore

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

		private const val TAG = "UriUtil"
	}
}
