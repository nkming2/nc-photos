abstract class FileDownloader {
  /// Download a file
  ///
  /// The return data depends on the platform
  /// - web: null
  /// - android: Uri to the downloaded file
  ///
  /// [parentDir] is a hint that set the parent directory where the files are
  /// saved. Whether this is supported or not is implementation specific
  ///
  /// [shouldNotify] is a hint that suggest whether to notify user about the
  /// progress. The actual decision is made by the underlying platform code and
  /// is not guaranteed to respect this flag
  Future<dynamic> downloadUrl({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    String? parentDir,
    bool? shouldNotify,
  });
}
