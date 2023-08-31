package com.nkming.nc_photos.np_platform_permission

import androidx.annotation.NonNull
import com.nkming.nc_photos.np_android_core.PermissionUtil
import com.nkming.nc_photos.np_android_core.logE
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

class NpPlatformPermissionPlugin : FlutterPlugin, ActivityAware,
    PluginRegistry.RequestPermissionsResultListener {
    companion object {
        private const val TAG = "NpPlatformPermissionPlugin"
    }

    override fun onAttachedToEngine(
        @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
    ) {
        permissionChannelHandler =
            PermissionChannelHandler(flutterPluginBinding.applicationContext)
        permissionChannel = EventChannel(
            flutterPluginBinding.binaryMessenger,
            PermissionChannelHandler.EVENT_CHANNEL
        )
        permissionChannel.setStreamHandler(permissionChannelHandler)
        permissionMethodChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            PermissionChannelHandler.METHOD_CHANNEL
        )
        permissionMethodChannel.setMethodCallHandler(permissionChannelHandler)
    }

    override fun onDetachedFromEngine(
        @NonNull binding: FlutterPlugin.FlutterPluginBinding
    ) {
        permissionChannel.setStreamHandler(null)
        permissionMethodChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        permissionChannelHandler.onAttachedToActivity(binding)
        pluginBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(
        binding: ActivityPluginBinding
    ) {
        permissionChannelHandler.onReattachedToActivityForConfigChanges(binding)
        pluginBinding = binding
        binding.addRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivity() {
        permissionChannelHandler.onDetachedFromActivity()
        pluginBinding?.removeRequestPermissionsResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        permissionChannelHandler.onDetachedFromActivityForConfigChanges()
        pluginBinding?.removeRequestPermissionsResultListener(this)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<String>, grantResults: IntArray
    ): Boolean {
        return try {
            when (requestCode) {
                PermissionUtil.REQUEST_CODE -> {
                    permissionChannelHandler.onRequestPermissionsResult(
                        requestCode, permissions, grantResults
                    )
                }

                else -> false
            }
        } catch (e: Throwable) {
            logE(
                TAG, "Failed while onActivityResult, requestCode=$requestCode"
            )
            false
        }
    }

    private var pluginBinding: ActivityPluginBinding? = null

    private lateinit var permissionChannel: EventChannel
    private lateinit var permissionMethodChannel: MethodChannel
    private lateinit var permissionChannelHandler: PermissionChannelHandler
}
