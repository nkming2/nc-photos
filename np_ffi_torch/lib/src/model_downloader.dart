import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// A running job has been canceled
class JobCanceledException implements Exception {
  const JobCanceledException([this.message]);

  @override
  String toString() {
    return "JobCanceledException: $message";
  }

  final dynamic message;
}

enum ModelType {
  realEsrganX4Vk,
  nafnetGopro,
  efficientDerain;

  Uri toRemoteUri() {
    return switch (this) {
      realEsrganX4Vk => Uri.https(
        "nc-photos.web.app",
        "/link/torch/real-esrgan-x4-vk",
      ),
      nafnetGopro => Uri.https(
        "nc-photos.web.app",
        "/link/torch/nafnet-gopro-32",
      ),
      efficientDerain => Uri.https(
        "nc-photos.web.app",
        "/link/torch/efficient-derain-spa",
      ),
    };
  }

  File toLocalFile(Directory root) {
    return switch (this) {
      realEsrganX4Vk => File("${root.path}/real-esrgan-x4-vk-1.pte"),
      nafnetGopro => File("${root.path}/nafnet-gopro-32.pte"),
      efficientDerain => File("${root.path}/efficient-derain-spa.pte"),
    };
  }
}

class ModelDownloader {
  Future<bool> isDownloaded(ModelType model) async {
    final dir = await _openDir();
    final modelFile = model.toLocalFile(dir);
    return modelFile.exists();
  }

  Future<File> download(
    ModelType model, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await _openDir();
    final modelFile = model.toLocalFile(dir);
    if (await modelFile.exists()) {
      _log.fine("[download] Return cached model at ${modelFile.path}");
      return modelFile;
    }

    final remoteUri = model.toRemoteUri();
    if (remoteUri.scheme == "file") {
      await File(remoteUri.path).copy(modelFile.path);
    } else {
      await _downloadHttp(
        from: model.toRemoteUri(),
        to: modelFile,
        onProgress: onProgress,
      );
    }
    return modelFile;
  }

  Future<void> delete(ModelType model) async {
    final dir = await _openDir();
    final modelFile = model.toLocalFile(dir);
    if (await modelFile.exists()) {
      await modelFile.delete();
    }
  }

  bool cancel() {
    _shouldInterrupt = true;
    return true;
  }

  Future<Directory> _openDir() async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory("${root.path}/torch");
    if (!await dir.exists()) {
      return dir.create();
    } else {
      return dir;
    }
  }

  Future<void> _downloadHttp({
    required Uri from,
    required File to,
    void Function(double progress)? onProgress,
  }) async {
    final temp = File("${to.path}.tmp");
    if (await temp.exists()) {
      await temp.delete();
    }
    try {
      // download file to a temp dir
      final fileWrite = temp.openWrite();
      try {
        final req = http.Request("GET", from);
        final response = await getHttpClient().send(req);
        bool isEnd = false;
        Object? error;
        final size = response.contentLength;
        var received = 0;
        final subscription = response.stream.listen(
          (value) {
            fileWrite.add(value);
            received += value.length;
            if (size != null && size > 0) {
              onProgress?.call((received / size).clamp(0, 1));
            }
          },
          onDone: () {
            isEnd = true;
          },
          onError: (e, stackTrace) {
            _log.severe("Failed while request", e, stackTrace);
            isEnd = true;
            error = e;
          },
          cancelOnError: true,
        );
        // wait until download finished
        while (!isEnd) {
          if (_shouldInterrupt) {
            await subscription.cancel();
            break;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
        if (error != null) {
          throw error!;
        }
      } finally {
        await fileWrite.flush();
        await fileWrite.close();
      }
      if (_shouldInterrupt) {
        throw const JobCanceledException();
      }

      if (await to.exists()) {
        await to.delete();
      }
      await temp.rename(to.path);
    } finally {
      try {
        await temp.delete();
      } catch (_) {}
    }
  }

  bool _shouldInterrupt = false;

  static http.Client getHttpClient() {
    return _httpClient ??= IOClient(HttpClient()..userAgent = "nc-photos");
  }

  static final _log = Logger("np_ffi_torch.ModelDownloader");

  static http.Client? _httpClient;
}
