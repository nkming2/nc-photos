import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/use_case/get_file_binary.dart';
import 'package:path/path.dart' as path;

class DownloadFile {
  DownloadFile(this._fileRepo);

  /// Download [file]
  ///
  /// The return data depends on the platform
  /// - web: null
  /// - android: Uri to the downloaded file
  Future<dynamic> call(Account account, File file) async {
    final content = await GetFileBinary(_fileRepo)(account, file);
    final saver = platform.FileSaver();
    return saver.saveFile(path.basename(file.path), content);
  }

  final FileRepo _fileRepo;
}
