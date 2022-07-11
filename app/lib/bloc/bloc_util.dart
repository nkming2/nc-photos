import 'package:nc_photos/account.dart';

String getInstNameForAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.userId.toCaseInsensitiveString()}@${account.address})";

String getInstNameForRootAwareAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.userId.toCaseInsensitiveString()}@${account.address}?${account.roots.join('&')})";
