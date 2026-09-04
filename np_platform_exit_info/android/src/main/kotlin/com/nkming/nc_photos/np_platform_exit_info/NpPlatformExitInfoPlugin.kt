package com.nkming.nc_photos.np_platform_exit_info

import android.app.Activity
import android.app.ActivityManager
import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

private class PigeonApiImpl : MyHostApi, ActivityAware {
    companion object {
        private const val TAG = "NpPlatformExitInfoPlugin"
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

    override fun getExifInfo(callback: (Result<ExitInfo?>) -> Unit) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            callback(Result.success(null))
            return
        }
        try {
            callback(Result.success(doGetExifInfo()))
        } catch (e: Throwable) {
            callback(Result.failure(e))
        }
    }

    @RequiresApi(Build.VERSION_CODES.R)
    private fun doGetExifInfo(): ExitInfo? {
        val am = context!!.getSystemService(Context.ACTIVITY_SERVICE) as ActivityManager
        val info = am.getHistoricalProcessExitReasons(null, 0, 1).firstOrNull() ?: return null
        return ExitInfo(
            description = info.description,
            pss = info.pss,
            reason = info.reason.toLong(),
            rss = info.rss,
            status = info.status.toLong(),
            timestamp = info.timestamp,
        )
    }

    private val context: Context?
        get() = activity

    private var activity: Activity? = null
}

class NpPlatformExitInfoPlugin : FlutterPlugin, ActivityAware {
    override fun onAttachedToEngine(
        flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        val api = PigeonApiImpl()
        MyHostApi.setUp(flutterPluginBinding.binaryMessenger, api)
        this.api = api
    }

    override fun onDetachedFromEngine(
        binding: FlutterPlugin.FlutterPluginBinding
    ) {
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        api?.onAttachedToActivity(binding)
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding
    ) {
        api?.onReattachedToActivityForConfigChanges(binding)
    }

    override fun onDetachedFromActivity() {
        api?.onDetachedFromActivity()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        api?.onDetachedFromActivityForConfigChanges()
    }

    private var api: PigeonApiImpl? = null
}
