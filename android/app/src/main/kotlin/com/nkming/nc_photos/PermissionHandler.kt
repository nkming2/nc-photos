package com.nkming.nc_photos

import android.Manifest
import android.app.Activity
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat

private const val PERMISSION_REQUEST_CODE = 11011

class PermissionHandler {
	companion object {
		fun ensureWriteExternalStorage(activity: Activity): Boolean {
			return if (ContextCompat.checkSelfPermission(
					activity, Manifest.permission.WRITE_EXTERNAL_STORAGE
				) != PackageManager.PERMISSION_GRANTED
			) {
				ActivityCompat.requestPermissions(
					activity,
					arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
					PERMISSION_REQUEST_CODE
				)
				false
			} else {
				true
			}
		}
	}
}
