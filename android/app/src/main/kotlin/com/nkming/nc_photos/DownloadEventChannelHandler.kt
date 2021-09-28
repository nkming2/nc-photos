package com.nkming.nc_photos

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import java.io.File

/**
 * Send DownloadManager ACTION_DOWNLOAD_COMPLETE events to flutter
 */
class DownloadEventCompleteChannelHandler(context: Context) :
	BroadcastReceiver(), EventChannel.StreamHandler {
	companion object {
		@JvmStatic
		val CHANNEL =
			"com.nkming.nc_photos/download_event/action_download_complete"
	}

	override fun onReceive(context: Context?, intent: Intent?) {
		if (intent?.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE || !intent.hasExtra(
				DownloadManager.EXTRA_DOWNLOAD_ID
			)
		) {
			return
		}

		val downloadId =
			intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, 0)
		// check the status of the job and retrieve the local URI
		val c = _downloadManager.query(
			DownloadManager.Query().setFilterById(downloadId)
		)
		if (c.moveToFirst()) {
			val status =
				c.getInt(c.getColumnIndex(DownloadManager.COLUMN_STATUS))
			if (status == DownloadManager.STATUS_SUCCESSFUL) {
				val uri =
					c.getString(c.getColumnIndex(DownloadManager.COLUMN_LOCAL_URI))
				val contentUri = FileProvider.getUriForFile(
					_context,
					"${BuildConfig.APPLICATION_ID}.fileprovider",
					File(Uri.parse(uri).path!!)
				)
				_eventSink?.success(
					mapOf(
						"downloadId" to downloadId,
						"uri" to contentUri.toString()
					)
				)
			} else if (status == DownloadManager.STATUS_FAILED) {
				val reason =
					c.getInt(c.getColumnIndex(DownloadManager.COLUMN_REASON))
				_eventSink?.error(
					"downloadError",
					"Download #$downloadId was not successful, status: $status, reason: $reason",
					mapOf(
						"downloadId" to downloadId
					)
				)
			}
		} else {
			Log.i(
				"DownloadEventCompleteChannelHandler.onReceive",
				"ID #$downloadId not found, user canceled the job?"
			)
			_eventSink?.error(
				"userCanceled", "Download #$downloadId was canceled", mapOf(
					"downloadId" to downloadId
				)
			)
		}
	}

	override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
		_context.registerReceiver(
			this, IntentFilter(DownloadManager.ACTION_DOWNLOAD_COMPLETE)
		)
		_eventSink = events
	}

	override fun onCancel(arguments: Any?) {
		_context.unregisterReceiver(this)
	}

	private val _context = context
	private var _eventSink: EventChannel.EventSink? = null
	private val _downloadManager by lazy {
		_context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
	}
}
