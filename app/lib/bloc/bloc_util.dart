import 'package:nc_photos/account.dart';

String getInstNameForAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.username.toCaseInsensitiveString()}@${account.address})";

String getInstNameForRootAwareAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.username.toCaseInsensitiveString()}@${account.address}?${account.roots.join('&')})";
