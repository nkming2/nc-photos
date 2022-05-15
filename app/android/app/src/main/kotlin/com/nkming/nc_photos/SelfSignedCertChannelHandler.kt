package com.nkming.nc_photos

import android.app.Activity
import com.nkming.nc_photos.plugin.logE
import io.flutter.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import javax.net.ssl.HttpsURLConnection

/*
 * Manage self-signed certs
 *
 * Methods:
 * Notify native side that changes have been made to the cert storage and thus
 * should reload them now
 * fun reload(): Unit
 */
class SelfSignedCertChannelHandler(activity: Activity) :
		MethodChannel.MethodCallHandler {
	companion object {
		const val CHANNEL = "com.nkming.nc_photos/self-signed-cert"
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		if (call.method == "reload") {
			try {
				reload(result)
			} catch (e: Throwable) {
				result.error("systemException", e.toString(), null)
			}
		} else {
			result.notImplemented()
		}
	}

	private fun reload(result: MethodChannel.Result) {
		_sslSocketFactory.reload(_context)
		_hostNameVerifier.reload(_context)
		result.success(null)
	}

	private val _activity = activity
	private val _context get() = _activity

	private val _sslSocketFactory = CustomSSLSocketFactory(_context)
	private val _hostNameVerifier = CustomHostnameVerifier(_context)

	init {
		try {
			HttpsURLConnection.setDefaultSSLSocketFactory(_sslSocketFactory)
			HttpsURLConnection.setDefaultHostnameVerifier(_hostNameVerifier)
		} catch (e: Exception) {
			logE("SelfSignedCertChannelHandler::init",
					"Failed while setting custom SSL handler, self-signed cert will not work",
					e)
		}
	}
}
