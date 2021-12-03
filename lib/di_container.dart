import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/face.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/pref.dart';

enum DiType {
  albumRepo,
  faceRepo,
  fileRepo,
  personRepo,
  shareRepo,
  shareeRepo,
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
    AppDb? appDb,
    Pref? pref,
  })  : _albumRepo = albumRepo,
        _faceRepo = faceRepo,
        _fileRepo = fileRepo,
        _personRepo = personRepo,
        _shareRepo = shareRepo,
        _shareeRepo = shareeRepo,
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
      case DiType.appDb:
        return contianer._appDb != null;
      case DiType.pref:
        return contianer._pref != null;
    }
  }

  AlbumRepo get albumRepo => _albumRepo!;
  FaceRepo get faceRepo => _faceRepo!;
  FileRepo get fileRepo => _fileRepo!;
  PersonRepo get personRepo => _personRepo!;
  ShareRepo get shareRepo => _shareRepo!;
  ShareeRepo get shareeRepo => _shareeRepo!;

  AppDb get appDb => _appDb!;
  Pref get pref => _pref!;

  final AlbumRepo? _albumRepo;
  final FaceRepo? _faceRepo;
  final FileRepo? _fileRepo;
  final PersonRepo? _personRepo;
  final ShareRepo? _shareRepo;
  final ShareeRepo? _shareeRepo;

  final AppDb? _appDb;
  final Pref? _pref;
}
