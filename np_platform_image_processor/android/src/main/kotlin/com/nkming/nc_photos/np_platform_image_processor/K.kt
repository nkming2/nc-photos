package com.nkming.nc_photos.np_platform_image_processor

internal interface K {
    companion object {
        const val LIB_ID = "com.nkming.nc_photos.np_platform_image_processor"

        const val IMAGE_PROCESSOR_SERVICE_NOTIFICATION_ID = 5000
        const val IMAGE_PROCESSOR_SERVICE_RESULT_NOTIFICATION_ID = 5001
        const val IMAGE_PROCESSOR_SERVICE_RESULT_FAILED_NOTIFICATION_ID = 5002

        const val ACTION_SHOW_IMAGE_PROCESSOR_RESULT =
            "${LIB_ID}.ACTION_SHOW_IMAGE_PROCESSOR_RESULT"

        const val EXTRA_IMAGE_RESULT_URI = "${LIB_ID}.EXTRA_IMAGE_RESULT_URI"
    }
}
