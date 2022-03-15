package com.nkming.nc_photos.plugin

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/*
 * Platform-side lock mechanism
 *
 * Method channel always run on the main thread, so this is safe even when
 * called from different isolates
 *
 * Methods:
 * Try acquiring an lock. Return true if successful, false if acquired by others.
 * fun tryLock(lockId: Int): Boolean
 *
 * Unlock a previously acquired lock. Unlocking twice is an error.
 * fun unlock(lockId: Int): Unit
 */
class LockChannelHandler : MethodChannel.MethodCallHandler {
	companion object {
		const val CHANNEL = "${K.LIB_ID}/lock"

		private val locks = mutableMapOf<Int, Boolean>()
	}

	override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
		when (call.method) {
			"tryLock" -> {
				try {
					tryLock(call.argument("lockId")!!, result)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}
			"unlock" -> {
				try {
					unlock(call.argument("lockId")!!, result)
				} catch (e: Throwable) {
					result.error("systemException", e.toString(), null)
				}
			}
			else -> {
				result.notImplemented()
			}
		}
	}

	private fun tryLock(lockId: Int, result: MethodChannel.Result) {
		if (locks[lockId] != true) {
			locks[lockId] = true
			result.success(true)
		} else {
			result.success(false)
		}
	}

	private fun unlock(lockId: Int, result: MethodChannel.Result) {
		if (locks[lockId] == true) {
			locks[lockId] = false
			result.success(null)
		} else {
			result.error(
				"notLockedException",
				"Cannot unlock without first locking",
				null
			)
		}
	}
}
