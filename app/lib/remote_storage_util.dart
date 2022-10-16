import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;

String getRemoteAlbumsDir(Account account) =>
    "${getRemoteStorageDir(account)}/albums";

String getRemotePendingSharedAlbumsDir(Account account) =>
    "${getRemoteStorageDir(account)}/shared_albums";

String getRemoteTouchDir(Account account) =>
    "${getRemoteStorageDir(account)}/touch";

String getRemoteLinkSharesDir(Account account) =>
    "${getRemoteStorageDir(account)}/link_shares";

String getRemoteStorageDir(Account account) =>
    "${api_util.getWebdavRootUrlRelative(account)}/$remoteStorageDirRelativePath";

const remoteStorageDirRelativePath = ".com.nkming.nc_photos";
