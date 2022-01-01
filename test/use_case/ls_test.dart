import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/use_case/ls.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as util;

void main() {
  group("Ls", () {
    test("normal", () async {
      expect(
          await Ls(_MockFileRepo())(
              util.buildAccount(),
              File(
                path: "remote.php/dav/files/admin",
              )),
          [
            File(
              path: "remote.php/dav/files/admin/test1.jpg",
            ),
            File(
              path: "remote.php/dav/files/admin/test2.jpg",
            ),
            File(
              path: "remote.php/dav/files/admin/d1",
              isCollection: true,
            ),
          ]);
    });
  });
}

class _MockFileRepo extends MockFileRepo {
  @override
  list(Account account, File root) async {
    return [
      File(
        path: "remote.php/dav/files/admin",
        isCollection: true,
      ),
      File(
        path: "remote.php/dav/files/admin/test1.jpg",
      ),
      File(
        path: "remote.php/dav/files/admin/test2.jpg",
      ),
      File(
        path: "remote.php/dav/files/admin/d1",
        isCollection: true,
      ),
      File(
        path: "remote.php/dav/files/admin/d1/test3.jpg",
      ),
    ]
        .where((element) =>
            element.path == root.path ||
            path.dirname(element.path) == root.path)
        .toList();
  }
}
