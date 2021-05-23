import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;

String getRemoteAlbumsDir(Account account) =>
    "${_getRemoteStorageDir(account)}/albums";

String _getRemoteStorageDir(Account account) =>
    "${api_util.getWebdavRootUrlRelative(account)}/.com.nkming.nc_photos";
