import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';

class Favorite with EquatableMixin {
  const Favorite({
    required this.fileId,
  });

  @override
  toString() => "$runtimeType {"
      "fileId: '$fileId', "
      "}";

  @override
  get props => [
        fileId,
      ];

  final int fileId;
}

class FavoriteRepo {
  const FavoriteRepo(this.dataSrc);

  /// See [FavoriteDataSource.list]
  Future<List<Favorite>> list(Account account, File dir) =>
      dataSrc.list(account, dir);

  final FavoriteDataSource dataSrc;
}

abstract class FavoriteDataSource {
  /// List all favorites for a user under [dir]
  Future<List<Favorite>> list(Account account, File dir);
}
