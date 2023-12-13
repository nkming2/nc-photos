import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:rxdart/rxdart.dart';

part 'account_pref_controller.g.dart';

@npLog
class AccountPrefController {
  AccountPrefController({
    required this.account,
  }) : _accountPref = AccountPref.of(account);

  void dispose() {
    _shareFolderController.close();
    _accountLabelController.close();
    _personProviderController.close();
    _isEnableMemoryAlbumController.close();
  }

  ValueStream<String> get shareFolder => _shareFolderController.stream;

  Future<void> setShareFolder(String value) => _set<String>(
        controller: _shareFolderController,
        setter: (pref, value) => pref.setShareFolder(value),
        value: value,
      );

  ValueStream<String?> get accountLabel => _accountLabelController.stream;

  Future<void> setAccountLabel(String? value) => _set<String?>(
        controller: _accountLabelController,
        setter: (pref, value) => pref.setAccountLabel(value),
        value: value,
      );

  ValueStream<PersonProvider> get personProvider =>
      _personProviderController.stream;

  Future<void> setPersonProvider(PersonProvider value) => _set<PersonProvider>(
        controller: _personProviderController,
        setter: (pref, value) => pref.setPersonProvider(value.index),
        value: value,
      );

  ValueStream<bool> get isEnableMemoryAlbum =>
      _isEnableMemoryAlbumController.stream;

  Future<void> setEnableMemoryAlbum(bool value) => _set<bool>(
        controller: _isEnableMemoryAlbumController,
        setter: (pref, value) => pref.setEnableMemoryAlbum(value),
        value: value,
      );

  Future<void> _set<T>({
    required BehaviorSubject<T> controller,
    required Future<bool> Function(AccountPref pref, T value) setter,
    required T value,
  }) async {
    final backup = controller.value;
    controller.add(value);
    try {
      if (!await setter(_accountPref, value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[_set] Failed setting preference", e, stackTrace);
      controller
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  final Account account;

  final AccountPref _accountPref;
  late final _shareFolderController =
      BehaviorSubject.seeded(_accountPref.getShareFolderOr(""));
  late final _accountLabelController =
      BehaviorSubject.seeded(_accountPref.getAccountLabel());
  late final _personProviderController = BehaviorSubject.seeded(
      PersonProvider.fromValue(_accountPref.getPersonProviderOr()));
  late final _isEnableMemoryAlbumController =
      BehaviorSubject.seeded(_accountPref.isEnableMemoryAlbumOr(true));
}
