import 'package:http/http.dart' as http;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/platform/file_downloader.dart' as itf;
import 'package:nc_photos/web/file_saver.dart';

class FileDownloader extends itf.FileDownloader {
  @override
  downloadUrl({
    required String url,
    Map<String, String>? headers,
    String? mimeType,
    required String filename,
    bool? shouldNotify,
  }) async {
    final uri = Uri.parse(url);
    final req = http.Request("GET", uri)..headers.addAll(headers ?? {});
    final response =
        await http.Response.fromStream(await http.Client().send(req));
    if (response.statusCode ~/ 100 != 2) {
      throw DownloadException(
          "Failed downloading $filename (HTTP ${response.statusCode})");
    }
    final saver = FileSaver();
    await saver.saveFile(filename, response.bodyBytes);
  }
}
