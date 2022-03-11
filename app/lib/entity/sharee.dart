import 'package:equatable/equatable.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';

enum ShareeType {
  user,
  group,
  remote,
  remoteGroup,
  email,
  circle,
  room,
  deck,
  lookup,
}

class Sharee with EquatableMixin {
  Sharee({
    required this.type,
    required this.label,
    required this.shareType,
    required this.shareWith,
    this.shareWithDisplayNameUnique,
  });

  @override
  toString() {
    var product = "$runtimeType {"
        "type: $type, "
        "label: $label, "
        "shareType: $shareType, "
        "shareWith: $shareWith, ";
    if (shareWithDisplayNameUnique != null) {
      product += "shareWithDisplayNameUnique: $shareWithDisplayNameUnique, ";
    }
    return product + "}";
  }

  @override
  get props => [
        type,
        label,
        shareType,
        shareWith,
        shareWithDisplayNameUnique,
      ];

  final ShareeType type;
  final String label;
  final int shareType;
  final CiString shareWith;
  final String? shareWithDisplayNameUnique;
}

class ShareeRepo {
  ShareeRepo(this.dataSrc);

  /// See [ShareeDataSource.list]
  Future<List<Sharee>> list(Account account) => dataSrc.list(account);

  final ShareeDataSource dataSrc;
}

abstract class ShareeDataSource {
  /// List all sharees of this account
  Future<List<Sharee>> list(Account account);
}
