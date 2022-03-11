import 'package:nc_photos/account.dart';
import 'package:nc_photos/pref.dart';

Future<AccountPref> loadAccountPref(Account account) async {
  final provider = PrefUniversalStorageProvider("accounts/${account.id}/pref");
  await provider.init();
  return AccountPref.scoped(provider);
}
