package com.nkming.nc_photos.plugin

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

interface PermissionUtil {
	companion object {
		fun request(activity: Activity, vararg permissions: String) {
			ActivityCompat.requestPermissions(
				activity, permissions, K.PERMISSION_REQUEST_CODE
			)
		}

		fun hasReadExternalStorage(context: Context): Boolean {
			return ContextCompat.checkSelfPermission(
				context, Manifest.permission.READ_EXTERNAL_STORAGE
			) == PackageManager.PERMISSION_GRANTED
		}

		fun requestReadExternalStorage(activity: Activity) =
			request(activity, Manifest.permission.READ_EXTERNAL_STORAGE)

		fun hasWriteExternalStorage(context: Context): Boolean {
			return ContextCompat.checkSelfPermission(
				context, Manifest.permission.WRITE_EXTERNAL_STORAGE
			) == PackageManager.PERMISSION_GRANTED
		}

		fun requestWriteExternalStorage(activity: Activity) =
			request(activity, Manifest.permission.WRITE_EXTERNAL_STORAGE)
	}
}
