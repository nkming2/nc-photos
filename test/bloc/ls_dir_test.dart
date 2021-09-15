import 'package:bloc_test/bloc_test.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/ls_dir.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../mock_type.dart';

void main() {
  _buildBloc() => LsDirBloc(fileRepo: _MockFileRepo());
  _buildAccount() => Account("http", "example.com", "admin", "pass", [""]);

  group("ListDir", () {
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
        act: (bloc) => bloc.add(LsDirBlocQuery(
            _buildAccount(), File(path: "remote.php/dav/files/admin"))),
        expect: () => [
          LsDirBlocLoading(
              _buildAccount(), File(path: "remote.php/dav/files/admin"), []),
          LsDirBlocSuccess(
              _buildAccount(), File(path: "remote.php/dav/files/admin"), [
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
        act: (bloc) => bloc.add(LsDirBlocQuery(
            _buildAccount(), File(path: "remote.php/dav/files/admin/d1"))),
        expect: () => [
          LsDirBlocLoading(
              _buildAccount(), File(path: "remote.php/dav/files/admin/d1"), []),
          LsDirBlocSuccess(
              _buildAccount(), File(path: "remote.php/dav/files/admin/d1"), [
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
        act: (bloc) => bloc.add(LsDirBlocQuery(
            _buildAccount(), File(path: "remote.php/dav/files/admin/d1/d2-2"))),
        expect: () => [
          LsDirBlocLoading(_buildAccount(),
              File(path: "remote.php/dav/files/admin/d1/d2-2"), []),
          LsDirBlocSuccess(_buildAccount(),
              File(path: "remote.php/dav/files/admin/d1/d2-2"), []),
        ],
      );

      blocTest<LsDirBloc, LsDirBlocState>(
        "query depth 2",
        build: _buildBloc,
        act: (bloc) => bloc.add(LsDirBlocQuery(
            _buildAccount(), File(path: "remote.php/dav/files/admin"),
            depth: 2)),
        expect: () => [
          LsDirBlocLoading(
              _buildAccount(), File(path: "remote.php/dav/files/admin"), []),
          LsDirBlocSuccess(
              _buildAccount(), File(path: "remote.php/dav/files/admin"), [
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
