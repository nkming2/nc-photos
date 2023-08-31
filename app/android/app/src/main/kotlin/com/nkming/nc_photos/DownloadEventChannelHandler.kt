package com.nkming.nc_photos

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import com.nkming.nc_photos.plugin.NcPhotosPlugin
import io.flutter.plugin.common.EventChannel

class DownloadEventCancelChannelHandler(context: Context) : BroadcastReceiver(),
    EventChannel.StreamHandler {
    companion object {
        @JvmStatic
        val CHANNEL =
            "com.nkming.nc_photos/download_event/action_download_cancel"
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent?.action != NcPhotosPlugin.ACTION_DOWNLOAD_CANCEL || !intent.hasExtra(
                NcPhotosPlugin.EXTRA_NOTIFICATION_ID
            )
        ) {
            return
        }

        val id = intent.getIntExtra(NcPhotosPlugin.EXTRA_NOTIFICATION_ID, 0)
        _eventSink?.success(
            mapOf(
                "notificationId" to id
            )
        )
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        _context.registerReceiver(
            this, IntentFilter(NcPhotosPlugin.ACTION_DOWNLOAD_CANCEL)
        )
        _eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        _context.unregisterReceiver(this)
    }

    private val _context = context
    private var _eventSink: EventChannel.EventSink? = null
}
