import 'package:nc_photos/use_case/find_file.dart';
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

void main() {
  util.initLog();
  group("FindFile", () {
    test("file", _findFile);
    test("missing file", _findMissingFile);
  });
}

/// Find a file in app db
///
/// Expect: return the file found
Future<void> _findFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()
        ..addJpeg("admin/test1.jpg")
        ..addJpeg("admin/test2.jpg"))
      .build();
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);

  expect(await FindFile(appDb)(account, 1), files[1]);
}

/// Find a file not existing in app db
///
/// Expect: throw StateError
Future<void> _findMissingFile() async {
  final account = util.buildAccount();
  final files = (util.FilesBuilder()..addJpeg("admin/test1.jpg")).build();
  final appDb = MockAppDb();
  await util.fillAppDb(appDb, account, files);

  expect(() => FindFile(appDb)(account, 1), throwsStateError);
}
