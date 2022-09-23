import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/search.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sqlite_table.dart' as sql;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/touch_manager.dart';

enum DiType {
  albumRepo,
  albumRepoLocal,
  faceRepo,
  fileRepo,
  fileRepoRemote,
  fileRepoLocal,
  personRepo,
  personRepoRemote,
  personRepoLocal,
  shareRepo,
  shareeRepo,
  favoriteRepo,
  tagRepo,
  tagRepoRemote,
  tagRepoLocal,
  taggedFileRepo,
  localFileRepo,
  searchRepo,
  pref,
  sqliteDb,
  touchManager,
}

class DiContainer {
  DiContainer({
    AlbumRepo? albumRepo,
    AlbumRepo? albumRepoLocal,
    FaceRepo? faceRepo,
    FileRepo? fileRepo,
    FileRepo? fileRepoRemote,
    FileRepo? fileRepoLocal,
    PersonRepo? personRepo,
    PersonRepo? personRepoRemote,
    PersonRepo? personRepoLocal,
    ShareRepo? shareRepo,
    ShareeRepo? shareeRepo,
    FavoriteRepo? favoriteRepo,
    TagRepo? tagRepo,
    TagRepo? tagRepoRemote,
    TagRepo? tagRepoLocal,
    TaggedFileRepo? taggedFileRepo,
    LocalFileRepo? localFileRepo,
    SearchRepo? searchRepo,
    Pref? pref,
    sql.SqliteDb? sqliteDb,
    TouchManager? touchManager,
  })  : _albumRepo = albumRepo,
        _albumRepoLocal = albumRepoLocal,
        _faceRepo = faceRepo,
        _fileRepo = fileRepo,
        _fileRepoRemote = fileRepoRemote,
        _fileRepoLocal = fileRepoLocal,
        _personRepo = personRepo,
        _personRepoRemote = personRepoRemote,
        _personRepoLocal = personRepoLocal,
        _shareRepo = shareRepo,
        _shareeRepo = shareeRepo,
        _favoriteRepo = favoriteRepo,
        _tagRepo = tagRepo,
        _tagRepoRemote = tagRepoRemote,
        _tagRepoLocal = tagRepoLocal,
        _taggedFileRepo = taggedFileRepo,
        _localFileRepo = localFileRepo,
        _searchRepo = searchRepo,
        _pref = pref,
        _sqliteDb = sqliteDb,
        _touchManager = touchManager;

  DiContainer.late();

  static bool has(DiContainer contianer, DiType type) {
    switch (type) {
      case DiType.albumRepo:
        return contianer._albumRepo != null;
      case DiType.albumRepoLocal:
        return contianer._albumRepoLocal != null;
      case DiType.faceRepo:
        return contianer._faceRepo != null;
      case DiType.fileRepo:
        return contianer._fileRepo != null;
      case DiType.fileRepoRemote:
        return contianer._fileRepoRemote != null;
      case DiType.fileRepoLocal:
        return contianer._fileRepoLocal != null;
      case DiType.personRepo:
        return contianer._personRepo != null;
      case DiType.personRepoRemote:
        return contianer._personRepoRemote != null;
      case DiType.personRepoLocal:
        return contianer._personRepoLocal != null;
      case DiType.shareRepo:
        return contianer._shareRepo != null;
      case DiType.shareeRepo:
        return contianer._shareeRepo != null;
      case DiType.favoriteRepo:
        return contianer._favoriteRepo != null;
      case DiType.tagRepo:
        return contianer._tagRepo != null;
      case DiType.tagRepoRemote:
        return contianer._tagRepoRemote != null;
      case DiType.tagRepoLocal:
        return contianer._tagRepoLocal != null;
      case DiType.taggedFileRepo:
        return contianer._taggedFileRepo != null;
      case DiType.localFileRepo:
        return contianer._localFileRepo != null;
      case DiType.searchRepo:
        return contianer._searchRepo != null;
      case DiType.pref:
        return contianer._pref != null;
      case DiType.sqliteDb:
        return contianer._sqliteDb != null;
      case DiType.touchManager:
        return contianer._touchManager != null;
    }
  }

  DiContainer copyWith({
    OrNull<AlbumRepo>? albumRepo,
    OrNull<FaceRepo>? faceRepo,
    OrNull<FileRepo>? fileRepo,
    OrNull<PersonRepo>? personRepo,
    OrNull<ShareRepo>? shareRepo,
    OrNull<ShareeRepo>? shareeRepo,
    OrNull<FavoriteRepo>? favoriteRepo,
    OrNull<TagRepo>? tagRepo,
    OrNull<TaggedFileRepo>? taggedFileRepo,
    OrNull<LocalFileRepo>? localFileRepo,
    OrNull<SearchRepo>? searchRepo,
    OrNull<Pref>? pref,
    OrNull<sql.SqliteDb>? sqliteDb,
    OrNull<TouchManager>? touchManager,
  }) {
    return DiContainer(
      albumRepo: albumRepo == null ? _albumRepo : albumRepo.obj,
      faceRepo: faceRepo == null ? _faceRepo : faceRepo.obj,
      fileRepo: fileRepo == null ? _fileRepo : fileRepo.obj,
      personRepo: personRepo == null ? _personRepo : personRepo.obj,
      shareRepo: shareRepo == null ? _shareRepo : shareRepo.obj,
      shareeRepo: shareeRepo == null ? _shareeRepo : shareeRepo.obj,
      favoriteRepo: favoriteRepo == null ? _favoriteRepo : favoriteRepo.obj,
      tagRepo: tagRepo == null ? _tagRepo : tagRepo.obj,
      taggedFileRepo:
          taggedFileRepo == null ? _taggedFileRepo : taggedFileRepo.obj,
      localFileRepo: localFileRepo == null ? _localFileRepo : localFileRepo.obj,
      searchRepo: searchRepo == null ? _searchRepo : searchRepo.obj,
      pref: pref == null ? _pref : pref.obj,
      sqliteDb: sqliteDb == null ? _sqliteDb : sqliteDb.obj,
      touchManager: touchManager == null ? _touchManager : touchManager.obj,
    );
  }

  AlbumRepo get albumRepo => _albumRepo!;
  AlbumRepo get albumRepoLocal => _albumRepoLocal!;
  FaceRepo get faceRepo => _faceRepo!;
  FileRepo get fileRepo => _fileRepo!;
  FileRepo get fileRepoRemote => _fileRepoRemote!;
  FileRepo get fileRepoLocal => _fileRepoLocal!;
  PersonRepo get personRepo => _personRepo!;
  PersonRepo get personRepoRemote => _personRepoRemote!;
  PersonRepo get personRepoLocal => _personRepoLocal!;
  ShareRepo get shareRepo => _shareRepo!;
  ShareeRepo get shareeRepo => _shareeRepo!;
  FavoriteRepo get favoriteRepo => _favoriteRepo!;
  TagRepo get tagRepo => _tagRepo!;
  TagRepo get tagRepoRemote => _tagRepoRemote!;
  TagRepo get tagRepoLocal => _tagRepoLocal!;
  TaggedFileRepo get taggedFileRepo => _taggedFileRepo!;
  LocalFileRepo get localFileRepo => _localFileRepo!;
  SearchRepo get searchRepo => _searchRepo!;
  TouchManager get touchManager => _touchManager!;

  sql.SqliteDb get sqliteDb => _sqliteDb!;
  Pref get pref => _pref!;

  set albumRepo(AlbumRepo v) {
    assert(_albumRepo == null);
    _albumRepo = v;
  }

  set albumRepoLocal(AlbumRepo v) {
    assert(_albumRepoLocal == null);
    _albumRepoLocal = v;
  }

  set faceRepo(FaceRepo v) {
    assert(_faceRepo == null);
    _faceRepo = v;
  }

  set fileRepo(FileRepo v) {
    assert(_fileRepo == null);
    _fileRepo = v;
  }

  set fileRepoRemote(FileRepo v) {
    assert(_fileRepoRemote == null);
    _fileRepoRemote = v;
  }

  set fileRepoLocal(FileRepo v) {
    assert(_fileRepoLocal == null);
    _fileRepoLocal = v;
  }

  set personRepo(PersonRepo v) {
    assert(_personRepo == null);
    _personRepo = v;
  }

  set personRepoRemote(PersonRepo v) {
    assert(_personRepoRemote == null);
    _personRepoRemote = v;
  }

  set personRepoLocal(PersonRepo v) {
    assert(_personRepoLocal == null);
    _personRepoLocal = v;
  }

  set shareRepo(ShareRepo v) {
    assert(_shareRepo == null);
    _shareRepo = v;
  }

  set shareeRepo(ShareeRepo v) {
    assert(_shareeRepo == null);
    _shareeRepo = v;
  }

  set favoriteRepo(FavoriteRepo v) {
    assert(_favoriteRepo == null);
    _favoriteRepo = v;
  }

  set tagRepo(TagRepo v) {
    assert(_tagRepo == null);
    _tagRepo = v;
  }

  set tagRepoRemote(TagRepo v) {
    assert(_tagRepoRemote == null);
    _tagRepoRemote = v;
  }

  set tagRepoLocal(TagRepo v) {
    assert(_tagRepoLocal == null);
    _tagRepoLocal = v;
  }

  set taggedFileRepo(TaggedFileRepo v) {
    assert(_taggedFileRepo == null);
    _taggedFileRepo = v;
  }

  set localFileRepo(LocalFileRepo v) {
    assert(_localFileRepo == null);
    _localFileRepo = v;
  }

  set searchRepo(SearchRepo v) {
    assert(_searchRepo == null);
    _searchRepo = v;
  }

  set touchManager(TouchManager v) {
    assert(_touchManager == null);
    _touchManager = v;
  }

  set sqliteDb(sql.SqliteDb v) {
    assert(_sqliteDb == null);
    _sqliteDb = v;
  }

  set pref(Pref v) {
    assert(_pref == null);
    _pref = v;
  }

  AlbumRepo? _albumRepo;
  // Explicitly request a AlbumRepo backed by local source
  AlbumRepo? _albumRepoLocal;
  FaceRepo? _faceRepo;
  FileRepo? _fileRepo;
  // Explicitly request a FileRepo backed by remote source
  FileRepo? _fileRepoRemote;
  // Explicitly request a FileRepo backed by local source
  FileRepo? _fileRepoLocal;
  PersonRepo? _personRepo;
  PersonRepo? _personRepoRemote;
  PersonRepo? _personRepoLocal;
  ShareRepo? _shareRepo;
  ShareeRepo? _shareeRepo;
  FavoriteRepo? _favoriteRepo;
  TagRepo? _tagRepo;
  TagRepo? _tagRepoRemote;
  TagRepo? _tagRepoLocal;
  TaggedFileRepo? _taggedFileRepo;
  LocalFileRepo? _localFileRepo;
  SearchRepo? _searchRepo;
  TouchManager? _touchManager;

  sql.SqliteDb? _sqliteDb;
  Pref? _pref;
}

extension DiContainerExtension on DiContainer {
  /// Uses local repo if available
  ///
  /// Notice that not all repo support this
  DiContainer withLocalRepo() => copyWith(
        albumRepo: OrNull(albumRepoLocal),
        fileRepo: OrNull(fileRepoLocal),
        personRepo: OrNull(personRepoLocal),
        tagRepo: OrNull(tagRepoLocal),
      );

  DiContainer withLocalAlbumRepo() =>
      copyWith(albumRepo: OrNull(albumRepoLocal));
  DiContainer withRemoteFileRepo() =>
      copyWith(fileRepo: OrNull(fileRepoRemote));
  DiContainer withLocalFileRepo() => copyWith(fileRepo: OrNull(fileRepoLocal));
  DiContainer withRemotePersonRepo() =>
      copyWith(personRepo: OrNull(personRepoRemote));
  DiContainer withLocalPersonRepo() =>
      copyWith(personRepo: OrNull(personRepoLocal));
  DiContainer withRemoteTagRepo() => copyWith(tagRepo: OrNull(tagRepoRemote));
  DiContainer withLocalTagRepo() => copyWith(tagRepo: OrNull(tagRepoLocal));
}
