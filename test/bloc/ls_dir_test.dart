import 'package:bloc_test/bloc_test.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/ls_dir.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../mock_type.dart';
import '../test_util.dart' as test_util;

void main() {
  _buildBloc() => LsDirBloc(_MockFileRepo());

  group("LsDirBloc", () {
    group("LsDirBlocQuery", () {
      test("initial state", () {
        final bloc = _buildBloc();
        expect(bloc.state.account, null);
        expect(bloc.state.root, File(path: ""));
        expect(bloc.state.items, []);
      });

      blocTest(
        "inital",
        build: _buildBloc,
        expect: () => [],
      );

      blocTest<LsDirBloc, LsDirBlocState>(
        "query 1 subdir",
        build: _buildBloc,
        act: (bloc) => bloc.add(LsDirBlocQuery(test_util.buildAccount(),
            File(path: "remote.php/dav/files/admin"))),
        expect: () => [
          LsDirBlocLoading(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin"), []),
          LsDirBlocSuccess(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin"), [
            LsDirBlocItem(
              File(
                path: "remote.php/dav/files/admin/d1",
                isCollection: true,
              ),
              null,
            ),
          ]),
        ],
      );

      blocTest<LsDirBloc, LsDirBlocState>(
        "query n subdir",
        build: _buildBloc,
        act: (bloc) => bloc.add(LsDirBlocQuery(test_util.buildAccount(),
            File(path: "remote.php/dav/files/admin/d1"))),
        expect: () => [
          LsDirBlocLoading(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin/d1"), []),
          LsDirBlocSuccess(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin/d1"), [
            LsDirBlocItem(
              File(
                path: "remote.php/dav/files/admin/d1/d2-1",
                isCollection: true,
              ),
              null,
            ),
            LsDirBlocItem(
              File(
                path: "remote.php/dav/files/admin/d1/d2-2",
                isCollection: true,
              ),
              null,
            ),
          ]),
        ],
      );

      blocTest<LsDirBloc, LsDirBlocState>(
        "query 0 subdir",
        build: _buildBloc,
        act: (bloc) => bloc.add(LsDirBlocQuery(test_util.buildAccount(),
            File(path: "remote.php/dav/files/admin/d1/d2-2"))),
        expect: () => [
          LsDirBlocLoading(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin/d1/d2-2"), []),
          LsDirBlocSuccess(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin/d1/d2-2"), []),
        ],
      );

      blocTest<LsDirBloc, LsDirBlocState>(
        "query depth 2",
        build: _buildBloc,
        act: (bloc) => bloc.add(LsDirBlocQuery(
            test_util.buildAccount(), File(path: "remote.php/dav/files/admin"),
            depth: 2)),
        expect: () => [
          LsDirBlocLoading(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin"), []),
          LsDirBlocSuccess(test_util.buildAccount(),
              File(path: "remote.php/dav/files/admin"), [
            LsDirBlocItem(
              File(
                path: "remote.php/dav/files/admin/d1",
                isCollection: true,
              ),
              [
                LsDirBlocItem(
                  File(
                    path: "remote.php/dav/files/admin/d1/d2-1",
                    isCollection: true,
                  ),
                  null,
                ),
                LsDirBlocItem(
                  File(
                    path: "remote.php/dav/files/admin/d1/d2-2",
                    isCollection: true,
                  ),
                  null,
                ),
              ],
            ),
          ]),
        ],
      );
    });
  });
}

class _MockFileRepo extends MockFileRepo {
  @override
  list(Account account, File root) async {
    return [
      File(
        path: "remote.php/dav/files/admin/test1.jpg",
      ),
      File(
        path: "remote.php/dav/files/admin/d1",
        isCollection: true,
      ),
      File(
        path: "remote.php/dav/files/admin/d1/test2.jpg",
      ),
      File(
        path: "remote.php/dav/files/admin/d1/d2-1",
        isCollection: true,
      ),
      File(
        path: "remote.php/dav/files/admin/d1/d2-2",
        isCollection: true,
      ),
      File(
        path: "remote.php/dav/files/admin/d1/d2-1/d3",
        isCollection: true,
      ),
    ].where((element) => path.dirname(element.path) == root.path).toList();
  }
}
