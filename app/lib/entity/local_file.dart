import 'package:equatable/equatable.dart';

abstract class LocalFile with EquatableMixin {
  const LocalFile();

  /// Compare the identity of two local files
  ///
  /// Return true if two Files point to the same local file on the device. Be
  /// careful that this does NOT mean that the two objects are identical
  bool compareIdentity(LocalFile other);

  String get logTag;

  String get filename;
  DateTime get lastModified;
  String? get mime;
  DateTime? get dateTaken;
}

extension LocalFileExtension on LocalFile {
  DateTime get bestDateTime => dateTaken ?? lastModified;
}

/// A local file represented by its content uri on Android
class LocalUriFile with EquatableMixin implements LocalFile {
  const LocalUriFile({
    required this.uri,
    required this.displayName,
    required this.path,
    required this.lastModified,
    this.mime,
    this.dateTaken,
  });

  @override
  compareIdentity(LocalFile other) {
    if (other is! LocalUriFile) {
      return false;
    } else {
      return uri == other.uri;
    }
  }

  @override
  toString() {
    var product = "$runtimeType {"
        "uri: $uri, "
        "displayName: $displayName, "
        "path: '$path', "
        "lastModified: $lastModified, ";
    if (mime != null) {
      product += "mime: $mime, ";
    }
    if (dateTaken != null) {
      product += "dateTaken: $dateTaken, ";
    }
    return product + "}";
  }

  @override
  get logTag => path;

  @override
  get filename => displayName;

  @override
  get props => [
        uri,
        displayName,
        path,
        lastModified,
        mime,
        dateTaken,
      ];

  final String uri;
  final String displayName;

  /// [path] could be a relative path or an absolute path
  final String path;
  @override
  final DateTime lastModified;
  @override
  final String? mime;
  @override
  final DateTime? dateTaken;
}

typedef LocalFileOnFailureListener = void Function(
    LocalFile file, Object? error, StackTrace? stackTrace);

class LocalFileRepo {
  const LocalFileRepo(this.dataSrc);

  /// See [LocalFileDataSource.listDir]
  Future<List<LocalFile>> listDir(String path) => dataSrc.listDir(path);

  /// See [LocalFileDataSource.deleteFiles]
  Future<void> deleteFiles(
    List<LocalFile> files, {
    LocalFileOnFailureListener? onFailure,
  }) =>
      dataSrc.deleteFiles(files, onFailure: onFailure);

  final LocalFileDataSource dataSrc;
}

abstract class LocalFileDataSource {
  /// List all files under [path]
  Future<List<LocalFile>> listDir(String path);

  /// Delete files
  Future<void> deleteFiles(
    List<LocalFile> files, {
    LocalFileOnFailureListener? onFailure,
  });
}
