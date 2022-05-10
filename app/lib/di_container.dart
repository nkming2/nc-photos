import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/favorite.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/entity/tagged_file.dart';
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';

enum DiType {
  albumRepo,
  faceRepo,
  fileRepo,
  personRepo,
  shareRepo,
  shareeRepo,
  favoriteRepo,
  tagRepo,
  taggedFileRepo,
  localFileRepo,
  appDb,
  pref,
}

class DiContainer {
  const DiContainer({
    AlbumRepo? albumRepo,
    FaceRepo? faceRepo,
    FileRepo? fileRepo,
    PersonRepo? personRepo,
    ShareRepo? shareRepo,
    ShareeRepo? shareeRepo,
    FavoriteRepo? favoriteRepo,
    TagRepo? tagRepo,
    TaggedFileRepo? taggedFileRepo,
    LocalFileRepo? localFileRepo,
    AppDb? appDb,
    Pref? pref,
  })  : _albumRepo = albumRepo,
        _faceRepo = faceRepo,
        _fileRepo = fileRepo,
        _personRepo = personRepo,
        _shareRepo = shareRepo,
        _shareeRepo = shareeRepo,
        _favoriteRepo = favoriteRepo,
        _tagRepo = tagRepo,
        _taggedFileRepo = taggedFileRepo,
        _localFileRepo = localFileRepo,
        _appDb = appDb,
        _pref = pref;

  static bool has(DiContainer contianer, DiType type) {
    switch (type) {
      case DiType.albumRepo:
        return contianer._albumRepo != null;
      case DiType.faceRepo:
        return contianer._faceRepo != null;
      case DiType.fileRepo:
        return contianer._fileRepo != null;
      case DiType.personRepo:
        return contianer._personRepo != null;
      case DiType.shareRepo:
        return contianer._shareRepo != null;
      case DiType.shareeRepo:
        return contianer._shareeRepo != null;
      case DiType.favoriteRepo:
        return contianer._favoriteRepo != null;
      case DiType.tagRepo:
        return contianer._tagRepo != null;
      case DiType.taggedFileRepo:
        return contianer._taggedFileRepo != null;
      case DiType.localFileRepo:
        return contianer._localFileRepo != null;
      case DiType.appDb:
        return contianer._appDb != null;
      case DiType.pref:
        return contianer._pref != null;
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
    OrNull<AppDb>? appDb,
    OrNull<Pref>? pref,
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
      appDb: appDb == null ? _appDb : appDb.obj,
      pref: pref == null ? _pref : pref.obj,
    );
  }

  AlbumRepo get albumRepo => _albumRepo!;
  FaceRepo get faceRepo => _faceRepo!;
  FileRepo get fileRepo => _fileRepo!;
  PersonRepo get personRepo => _personRepo!;
  ShareRepo get shareRepo => _shareRepo!;
  ShareeRepo get shareeRepo => _shareeRepo!;
  FavoriteRepo get favoriteRepo => _favoriteRepo!;
  TagRepo get tagRepo => _tagRepo!;
  TaggedFileRepo get taggedFileRepo => _taggedFileRepo!;
  LocalFileRepo get localFileRepo => _localFileRepo!;

  AppDb get appDb => _appDb!;
  Pref get pref => _pref!;

  final AlbumRepo? _albumRepo;
  final FaceRepo? _faceRepo;
  final FileRepo? _fileRepo;
  final PersonRepo? _personRepo;
  final ShareRepo? _shareRepo;
  final ShareeRepo? _shareeRepo;
  final FavoriteRepo? _favoriteRepo;
  final TagRepo? _tagRepo;
  final TaggedFileRepo? _taggedFileRepo;
  final LocalFileRepo? _localFileRepo;

  final AppDb? _appDb;
  final Pref? _pref;
}
