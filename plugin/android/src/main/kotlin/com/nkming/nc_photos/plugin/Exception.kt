package com.nkming.nc_photos.plugin

class PermissionException(message: String) : Exception(message)

class HttpException(statusCode: Int, message: String): Exception(message)
