import 'package:idb_shim/idb_client.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/string_extension.dart';

class PopulatePerson {
  /// Return a list of files of the faces
  Future<List<File>> call(Account account, List<Face> faces) async {
    return await AppDb.use((db) async {
      final transaction =
          db.transaction(AppDb.fileDbStoreName, idbModeReadOnly);
      final store = transaction.objectStore(AppDb.fileDbStoreName);
      final index = store.index(AppDbFileDbEntry.indexName);
      final products = <File>[];
      for (final f in faces) {
        try {
          products.add(await _populateOne(account, f, store, index));
        } catch (e, stackTrace) {
          _log.severe("[call] Failed populating file of face: ${f.fileId}", e,
              stackTrace);
        }
      }
      return products;
    });
  }

  Future<File> _populateOne(
      Account account, Face face, ObjectStore store, Index index) async {
    final List dbItems = await index
        .getAll(AppDbFileDbEntry.toNamespacedFileId(account, face.fileId));
    // find the one owned by us
    Map? dbItem;
    try {
      dbItem = dbItems.firstWhere((element) {
        final e = AppDbFileDbEntry.fromJson(element.cast<String, dynamic>());
        return file_util
            .getUserDirName(e.file)
            .equalsIgnoreCase(account.username);
      });
    } on StateError catch (_) {
      // not found
    }
    if (dbItem == null) {
      _log.warning(
          "[_populateOne] File doesn't exist in DB, removed?: '${face.fileId}'");
      throw CacheNotFoundException();
    }
    final dbEntry = AppDbFileDbEntry.fromJson(dbItem.cast<String, dynamic>());
    return dbEntry.file;
  }

  static final _log = Logger("use_case.populate_album.PopulatePerson");
}
