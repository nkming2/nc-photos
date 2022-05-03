package com.nkming.nc_photos.plugin

import android.annotation.SuppressLint
import android.app.Notification
import android.app.PendingIntent
import android.app.Service
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.net.Uri
import android.os.AsyncTask
import android.os.Bundle
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationChannelCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.nkming.nc_photos.plugin.image_processor.ZeroDce

class ImageProcessorService : Service() {
	companion object {
		const val EXTRA_METHOD = "method"
		const val METHOD_ZERO_DCE = "zero-dce"
		const val EXTRA_IMAGE = "image"
		const val EXTRA_FILENAME = "filename"

		private const val NOTIFICATION_ID =
			K.IMAGE_PROCESSOR_SERVICE_NOTIFICATION_ID
		private const val RESULT_NOTIFICATION_ID =
			K.IMAGE_PROCESSOR_SERVICE_RESULT_NOTIFICATION_ID
		private const val RESULT_FAILED_NOTIFICATION_ID =
			K.IMAGE_PROCESSOR_SERVICE_RESULT_FAILED_NOTIFICATION_ID
		private const val CHANNEL_ID = "ImageProcessorService"

		const val TAG = "ImageProcessorService"
	}

	override fun onBind(intent: Intent?): IBinder? = null

	@SuppressLint("WakelockTimeout")
	override fun onCreate() {
		Log.i(TAG, "[onCreate] Service created")
		super.onCreate()
		wakeLock.acquire()
		createNotificationChannel()
	}

	override fun onDestroy() {
		Log.i(TAG, "[onDestroy] Service destroyed")
		wakeLock.release()
		super.onDestroy()
	}

	override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {
		assert(intent.hasExtra(EXTRA_METHOD))
		assert(intent.hasExtra(EXTRA_IMAGE))
		if (!isForeground) {
			try {
				startForeground(NOTIFICATION_ID, buildNotification())
				isForeground = true
			} catch (e: Throwable) {
				// ???
				Log.e(TAG, "[onStartCommand] Failed while startForeground", e)
			}
		}

		val method = intent.getStringExtra(EXTRA_METHOD)
		when (method) {
			METHOD_ZERO_DCE -> onZeroDce(startId, intent.extras!!)
			else -> {
				Log.e(TAG, "Unknown method: $method")
				// we can't call stopSelf here as it'll stop the service even if
				// there are commands running in the bg
				addCommand(
					ImageProcessorCommand(startId, "null", Uri.EMPTY, "")
				)
			}
		}
		return START_REDELIVER_INTENT
	}

	private fun onZeroDce(startId: Int, extras: Bundle) {
		val imageUri = Uri.parse(extras.getString(EXTRA_IMAGE)!!)
		val filename = extras.getString(EXTRA_FILENAME)!!
		addCommand(
			ImageProcessorCommand(startId, METHOD_ZERO_DCE, imageUri, filename)
		)
	}

	private fun createNotificationChannel() {
		val channel = NotificationChannelCompat.Builder(
			CHANNEL_ID, NotificationManagerCompat.IMPORTANCE_LOW
		).run {
			setName("Image processing")
			setDescription("Enhance images in the background")
			build()
		}
		notificationManager.createNotificationChannel(channel)
	}

	private fun buildNotification(content: String? = null): Notification {
		return NotificationCompat.Builder(this, CHANNEL_ID).run {
			setSmallIcon(R.drawable.outline_auto_fix_high_white_24)
			setContentTitle("Processing image")
			if (content != null) setContentText(content)
			build()
		}
	}

	private fun buildResultNotification(result: Uri): Notification {
		val intent = Intent().apply {
			`package` = packageName
			component = ComponentName(
				"com.nkming.nc_photos", "com.nkming.nc_photos.MainActivity"
			)
			action = K.ACTION_SHOW_IMAGE_PROCESSOR_RESULT
			putExtra(K.EXTRA_IMAGE_RESULT_URI, result)
		}
		val pi = PendingIntent.getActivity(
			this, 0, intent,
			PendingIntent.FLAG_UPDATE_CURRENT or getPendingIntentFlagImmutable()
		)
		return NotificationCompat.Builder(this, CHANNEL_ID).run {
			setSmallIcon(R.drawable.outline_image_white_24)
			setContentTitle("Successfully enhanced image")
			setContentText("Tap to view the result")
			setContentIntent(pi)
			setAutoCancel(true)
			build()
		}
	}

	private fun buildResultFailedNotification(
		exception: Throwable
	): Notification {
		return NotificationCompat.Builder(this, CHANNEL_ID).run {
			setSmallIcon(R.drawable.outline_image_white_24)
			setContentTitle("Failed enhancing image")
			setContentText(exception.message)
			build()
		}
	}

	private fun addCommand(cmd: ImageProcessorCommand) {
		cmds.add(cmd)
		if (cmdTask == null) {
			runCommand()
		}
	}

	@SuppressLint("StaticFieldLeak")
	private fun runCommand() {
		val cmd = cmds.first()
		notificationManager.notify(
			NOTIFICATION_ID, buildNotification(cmd.filename)
		)
		cmdTask = object : ImageProcessorCommandTask(applicationContext) {
			override fun onPostExecute(result: MessageEvent) {
				notifyResult(result)
				cmds.removeFirst()
				stopSelf(cmd.startId)
				if (cmds.isNotEmpty()) {
					runCommand()
				} else {
					cmdTask = null
				}
			}
		}.apply {
			@Suppress("Deprecation")
			executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR, cmd)
		}
	}

	private fun notifyResult(event: MessageEvent) {
		if (event is ImageProcessorCompletedEvent) {
			notificationManager.notify(
				RESULT_NOTIFICATION_ID, buildResultNotification(event.result)
			)
		} else if (event is ImageProcessorFailedEvent) {
			notificationManager.notify(
				RESULT_FAILED_NOTIFICATION_ID,
				buildResultFailedNotification(event.exception)
			)
		}
	}

	private var isForeground = false
	private val cmds = mutableListOf<ImageProcessorCommand>()
	private var cmdTask: ImageProcessorCommandTask? = null

	private val notificationManager by lazy {
		NotificationManagerCompat.from(this)
	}
	private val wakeLock: PowerManager.WakeLock by lazy {
		(getSystemService(Context.POWER_SERVICE) as PowerManager).newWakeLock(
			PowerManager.PARTIAL_WAKE_LOCK, "nc-photos:ImageProcessorService"
		).apply {
			setReferenceCounted(false)
		}
	}
}

private data class ImageProcessorCommand(
	val startId: Int,
	val method: String,
	val uri: Uri,
	val filename: String,
	val args: Map<String, Any> = mapOf(),
)

@Suppress("Deprecation")
private open class ImageProcessorCommandTask(context: Context) :
	AsyncTask<ImageProcessorCommand, Unit, MessageEvent>() {
	companion object {
		private const val TAG = "ImageProcessorCommandTask"
	}

	override fun doInBackground(
		vararg params: ImageProcessorCommand?
	): MessageEvent {
		val cmd = params[0]!!
		return try {
			val output = when (cmd.method) {
				ImageProcessorService.METHOD_ZERO_DCE -> ZeroDce(context).infer(
					cmd.uri
				)
				else -> throw IllegalArgumentException(
					"Unknown method: ${cmd.method}"
				)
			}
			val uri = saveBitmap(output, cmd.filename)
			ImageProcessorCompletedEvent(cmd.uri, uri)
		} catch (e: Throwable) {
			ImageProcessorFailedEvent(cmd.uri, e)
		}
	}

	private fun saveBitmap(bitmap: Bitmap, filename: String): Uri {
		return MediaStoreUtil.writeFileToDownload(
			context, {
				bitmap.compress(Bitmap.CompressFormat.JPEG, 85, it)
			}, filename, "Photos (for Nextcloud)/Enhanced Photos"
		)
	}

	@SuppressLint("StaticFieldLeak")
	private val context = context
}
