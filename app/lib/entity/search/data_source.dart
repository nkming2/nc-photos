import 'package:drift/drift.dart' as sql;
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/person/builder.dart';
import 'package:nc_photos/entity/search.dart';
import 'package:nc_photos/entity/search_util.dart' as search_util;
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/sqlite/files_query_builder.dart' as sql;
import 'package:nc_photos/entity/sqlite/type_converter.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/list_tagged_file.dart';
import 'package:nc_photos/use_case/person/list_person_face.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/ci_string.dart';

part 'data_source.g.dart';

@npLog
class SearchSqliteDbDataSource implements SearchDataSource {
  SearchSqliteDbDataSource(this._c);

  @override
  list(Account account, SearchCriteria criteria) async {
    _log.info("[list] $criteria");
    final stopwatch = Stopwatch()..start();
    try {
      final keywords = search_util
          .cleanUpSymbols(criteria.input)
          .split(" ")
          .where((s) => s.isNotEmpty)
          .map((s) => s.toCi().toCaseInsensitiveString())
          .toSet();
      final futures = await Future.wait([
        _listByPath(account, criteria, keywords),
        _listByLocation(account, criteria),
        _listByTag(account, criteria),
        _listByPerson(account, criteria),
      ]);
      return futures.flatten().distinctIf(
            (a, b) => a.compareServerIdentity(b),
            (a) => a.identityHashCode,
          );
    } finally {
      _log.info("[list] Elapsed time: ${stopwatch.elapsedMilliseconds}ms");
    }
  }

  Future<List<File>> _listByPath(
      Account account, SearchCriteria criteria, Set<String> keywords) async {
    try {
      final dbFiles = await _c.sqliteDb.use((db) async {
        final query = db.queryFiles().run((q) {
          q.setQueryMode(sql.FilesQueryMode.completeFile);
          q.setAppAccount(account);
          for (final r in account.roots) {
            if (r.isNotEmpty) {
              q.byOrRelativePathPattern("$r/%");
            }
          }
          for (final f in criteria.filters) {
            f.apply(q);
          }
          return q.build();
        });
        // limit to supported formats only
        query.where(db.files.contentType.like("image/%") |
            db.files.contentType.like("video/%"));
        for (final k in keywords) {
          query.where(db.accountFiles.relativePath.like("%$k%"));
        }
        return await query
            .map((r) => sql.CompleteFile(
                  r.readTable(db.files),
                  r.readTable(db.accountFiles),
                  r.readTableOrNull(db.images),
                  r.readTableOrNull(db.imageLocations),
                  r.readTableOrNull(db.trashes),
                ))
            .get();
      });
      return await dbFiles.convertToAppFile(account);
    } catch (e, stackTrace) {
      _log.severe("[_listByPath] Failed while _listByPath", e, stackTrace);
      return [];
    }
  }

  Future<List<File>> _listByLocation(
      Account account, SearchCriteria criteria) async {
    // location search requires exact match, for example, searching "united"
    // will NOT return results from US, UK, UAE, etc. Searching by the alpha2
    // code is supported
    try {
      final dbFiles = await _c.sqliteDb.use((db) async {
        final query = db.queryFiles().run((q) {
          q.setQueryMode(sql.FilesQueryMode.completeFile);
          q.setAppAccount(account);
          for (final r in account.roots) {
            if (r.isNotEmpty) {
              q.byOrRelativePathPattern("$r/%");
            }
          }
          for (final f in criteria.filters) {
            f.apply(q);
          }
          q.byLocation(criteria.input);
          return q.build();
        });
        // limit to supported formats only
        query.where(db.files.contentType.like("image/%") |
            db.files.contentType.like("video/%"));
        return await query
            .map((r) => sql.CompleteFile(
                  r.readTable(db.files),
                  r.readTable(db.accountFiles),
                  r.readTableOrNull(db.images),
                  r.readTableOrNull(db.imageLocations),
                  r.readTableOrNull(db.trashes),
                ))
            .get();
      });
      return await dbFiles.convertToAppFile(account);
    } catch (e, stackTrace) {
      _log.severe(
          "[_listByLocation] Failed while _listByLocation", e, stackTrace);
      return [];
    }
  }

  Future<List<File>> _listByTag(
      Account account, SearchCriteria criteria) async {
    // tag search requires exact match, for example, searching "super" will NOT
    // return results from "super tag"
    try {
      final dbTag = await _c.sqliteDb.use((db) async {
        return await db.tagByDisplayName(
          appAccount: account,
          displayName: criteria.input,
        );
      });
      if (dbTag == null) {
        return [];
      }
      final tag = SqliteTagConverter.fromSql(dbTag);
      _log.info("[_listByTag] Found tag: ${tag.displayName}");
      final files = await ListTaggedFile(_c)(account, [tag]);
      return files
          .where((f) => criteria.filters.every((c) => c.isSatisfy(f)))
          .toList();
    } catch (e, stackTrace) {
      _log.severe("[_listByTag] Failed while _listByTag", e, stackTrace);
      return [];
    }
  }

  Future<List<File>> _listByPerson(
      Account account, SearchCriteria criteria) async {
    // person search requires exact match of any parts, for example, searching
    // "Ada" will return results from "Ada Crook" but NOT "Adabelle"
    try {
      final dbPersons = await _c.sqliteDb.use((db) async {
        return await db.faceRecognitionPersonsByName(
          appAccount: account,
          name: criteria.input,
        );
      });
      if (dbPersons.isEmpty) {
        return [];
      }
      final persons = (await dbPersons.convertToAppFaceRecognitionPerson())
          .map((p) => PersonBuilder.byFaceRecognitionPerson(account, p))
          .toList();
      _log.info(
          "[_listByPerson] Found people: ${persons.map((p) => p.name).toReadableString()}");
      final futures = await Future.wait(
          persons.map((p) async => ListPersonFace(_c)(account, p).last));
      final faces = futures.flatten().toList();
      final files = await InflateFileDescriptor(_c)
          .call(account, faces.map((e) => e.file).toList());
      return files
          .where((f) => criteria.filters.every((c) => c.isSatisfy(f)))
          .toList();
    } catch (e, stackTrace) {
      _log.severe("[_listByPerson] Failed while _listByPerson", e, stackTrace);
      return [];
    }
  }

  final DiContainer _c;
}
