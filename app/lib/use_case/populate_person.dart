import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception.dart';

class PopulatePerson {
  const PopulatePerson(this.appDb);

  /// Return a list of files of the faces
  Future<List<File>> call(Account account, List<Face> faces) async {
    return await appDb.use(
      (db) => db.transaction(AppDb.file2StoreName, idbModeReadOnly),
      (transaction) async {
        final store = transaction.objectStore(AppDb.file2StoreName);
        final products = <File>[];
        for (final f in faces) {
          try {
            products.add(await _populateOne(account, f, fileStore: store));
          } catch (e, stackTrace) {
            _log.severe("[call] Failed populating file of face: ${f.fileId}", e,
                stackTrace);
          }
        }
        return products;
      },
    );
  }

  Future<File> _populateOne(
    Account account,
    Face face, {
    required ObjectStore fileStore,
  }) async {
    final dbItem = await fileStore
        .getObject(AppDbFile2Entry.toPrimaryKey(account, face.fileId)) as Map?;
    if (dbItem == null) {
      _log.warning(
          "[_populateOne] File doesn't exist in DB, removed?: '${face.fileId}'");
      throw CacheNotFoundException();
    }
    final dbEntry = AppDbFile2Entry.fromJson(dbItem.cast<String, dynamic>());
    return dbEntry.file;
  }

  final AppDb appDb;

  static final _log = Logger("use_case.populate_album.PopulatePerson");
}
