import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/repo2.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/nc_album/repo.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/entity/search.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/touch_manager.dart';

enum DiType {
  albumRepo,
  albumRepoRemote,
  albumRepoLocal,
  albumRepo2,
  albumRepo2Remote,
  albumRepo2Local,
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
  ncAlbumRepo,
  ncAlbumRepoRemote,
  ncAlbumRepoLocal,
  pref,
  sqliteDb,
  touchManager,
}

class DiContainer {
  DiContainer({
    AlbumRepo? albumRepo,
    AlbumRepo? albumRepoRemote,
    AlbumRepo? albumRepoLocal,
    AlbumRepo2? albumRepo2,
    AlbumRepo2? albumRepo2Remote,
    AlbumRepo2? albumRepo2Local,
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
    NcAlbumRepo? ncAlbumRepo,
    NcAlbumRepo? ncAlbumRepoRemote,
    NcAlbumRepo? ncAlbumRepoLocal,
    Pref? pref,
    sql.SqliteDb? sqliteDb,
    TouchManager? touchManager,
  })  : _albumRepo = albumRepo,
        _albumRepoRemote = albumRepoRemote,
        _albumRepoLocal = albumRepoLocal,
        _albumRepo2 = albumRepo2,
        _albumRepo2Remote = albumRepo2Remote,
        _albumRepo2Local = albumRepo2Local,
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
        _ncAlbumRepo = ncAlbumRepo,
        _ncAlbumRepoRemote = ncAlbumRepoRemote,
        _ncAlbumRepoLocal = ncAlbumRepoLocal,
        _pref = pref,
        _sqliteDb = sqliteDb,
        _touchManager = touchManager;

  DiContainer.late();

  static bool has(DiContainer contianer, DiType type) {
    switch (type) {
      case DiType.albumRepo:
        return contianer._albumRepo != null;
      case DiType.albumRepoRemote:
        return contianer._albumRepoRemote != null;
      case DiType.albumRepoLocal:
        return contianer._albumRepoLocal != null;
      case DiType.albumRepo2:
        return contianer._albumRepo2 != null;
      case DiType.albumRepo2Remote:
        return contianer._albumRepo2Remote != null;
      case DiType.albumRepo2Local:
        return contianer._albumRepo2Local != null;
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
      case DiType.ncAlbumRepo:
        return contianer._ncAlbumRepo != null;
      case DiType.ncAlbumRepoRemote:
        return contianer._ncAlbumRepoRemote != null;
      case DiType.ncAlbumRepoLocal:
        return contianer._ncAlbumRepoLocal != null;
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
    OrNull<AlbumRepo2>? albumRepo2,
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
    OrNull<NcAlbumRepo>? ncAlbumRepo,
    OrNull<Pref>? pref,
    OrNull<sql.SqliteDb>? sqliteDb,
    OrNull<TouchManager>? touchManager,
  }) {
    return DiContainer(
      albumRepo: albumRepo == null ? _albumRepo : albumRepo.obj,
      albumRepo2: albumRepo2 == null ? _albumRepo2 : albumRepo2.obj,
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
      ncAlbumRepo: ncAlbumRepo == null ? _ncAlbumRepo : ncAlbumRepo.obj,
      pref: pref == null ? _pref : pref.obj,
      sqliteDb: sqliteDb == null ? _sqliteDb : sqliteDb.obj,
      touchManager: touchManager == null ? _touchManager : touchManager.obj,
    );
  }

  AlbumRepo get albumRepo => _albumRepo!;
  AlbumRepo get albumRepoRemote => _albumRepoRemote!;
  AlbumRepo get albumRepoLocal => _albumRepoLocal!;
  AlbumRepo2 get albumRepo2 => _albumRepo2!;
  AlbumRepo2 get albumRepo2Remote => _albumRepo2Remote!;
  AlbumRepo2 get albumRepo2Local => _albumRepo2Local!;
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
  NcAlbumRepo get ncAlbumRepo => _ncAlbumRepo!;
  NcAlbumRepo get ncAlbumRepoRemote => _ncAlbumRepoRemote!;
  NcAlbumRepo get ncAlbumRepoLocal => _ncAlbumRepoLocal!;
  TouchManager get touchManager => _touchManager!;

  sql.SqliteDb get sqliteDb => _sqliteDb!;
  Pref get pref => _pref!;

  set albumRepo(AlbumRepo v) {
    assert(_albumRepo == null);
    _albumRepo = v;
  }

  set albumRepoRemote(AlbumRepo v) {
    assert(_albumRepoRemote == null);
    _albumRepoRemote = v;
  }

  set albumRepoLocal(AlbumRepo v) {
    assert(_albumRepoLocal == null);
    _albumRepoLocal = v;
  }

  set albumRepo2(AlbumRepo2 v) {
    assert(_albumRepo2 == null);
    _albumRepo2 = v;
  }

  set albumRepo2Remote(AlbumRepo2 v) {
    assert(_albumRepo2Remote == null);
    _albumRepo2Remote = v;
  }

  set albumRepo2Local(AlbumRepo2 v) {
    assert(_albumRepo2Local == null);
    _albumRepo2Local = v;
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

  set ncAlbumRepo(NcAlbumRepo v) {
    assert(_ncAlbumRepo == null);
    _ncAlbumRepo = v;
  }

  set ncAlbumRepoRemote(NcAlbumRepo v) {
    assert(_ncAlbumRepoRemote == null);
    _ncAlbumRepoRemote = v;
  }

  set ncAlbumRepoLocal(NcAlbumRepo v) {
    assert(_ncAlbumRepoLocal == null);
    _ncAlbumRepoLocal = v;
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
  AlbumRepo? _albumRepoRemote;
  // Explicitly request a AlbumRepo backed by local source
  AlbumRepo? _albumRepoLocal;
  FaceRepo? _faceRepo;
  AlbumRepo2? _albumRepo2;
  AlbumRepo2? _albumRepo2Remote;
  AlbumRepo2? _albumRepo2Local;
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
  NcAlbumRepo? _ncAlbumRepo;
  NcAlbumRepo? _ncAlbumRepoRemote;
  NcAlbumRepo? _ncAlbumRepoLocal;
  TouchManager? _touchManager;

  sql.SqliteDb? _sqliteDb;
  Pref? _pref;
}

extension DiContainerExtension on DiContainer {
  /// Uses remote repo if available
  ///
  /// Notice that not all repo support this
  DiContainer withRemoteRepo() => copyWith(
        albumRepo: OrNull(albumRepoRemote),
        albumRepo2: OrNull(albumRepo2Remote),
        fileRepo: OrNull(fileRepoRemote),
        personRepo: OrNull(personRepoRemote),
        tagRepo: OrNull(tagRepoRemote),
        ncAlbumRepo: OrNull(ncAlbumRepoRemote),
      );

  /// Uses local repo if available
  ///
  /// Notice that not all repo support this
  DiContainer withLocalRepo() => copyWith(
        albumRepo: OrNull(albumRepoLocal),
        albumRepo2: OrNull(albumRepo2Local),
        fileRepo: OrNull(fileRepoLocal),
        personRepo: OrNull(personRepoLocal),
        tagRepo: OrNull(tagRepoLocal),
        ncAlbumRepo: OrNull(ncAlbumRepoLocal),
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
