import 'package:nc_photos/account.dart';

String getInstNameForAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.username}@${account.address})";

String getInstNameForRootAwareAccount(String className, Account account) =>
    "$className(${account.scheme}://${account.username}@${account.address}?${account.roots.join('&')})";
