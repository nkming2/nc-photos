package com.nkming.nc_photos.np_platform_image_processor

internal class HttpException(statusCode: Int, message: String) :
	Exception(message)

internal class NativeException(message: String) : Exception(message)
