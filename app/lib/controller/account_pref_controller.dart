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
  }

  ValueStream<String> get shareFolder => _shareFolderController.stream;

  Future<void> setShareFolder(String value) async {
    final backup = _shareFolderController.value;
    _shareFolderController.add(value);
    try {
      if (!await _accountPref.setShareFolder(value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[setShareFolder] Failed setting preference", e, stackTrace);
      _shareFolderController
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  ValueStream<String?> get accountLabel => _accountLabelController.stream;

  Future<void> setAccountLabel(String? value) async {
    final backup = _accountLabelController.value;
    _accountLabelController.add(value);
    try {
      if (!await _accountPref.setAccountLabel(value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[setAccountLabel] Failed setting preference", e, stackTrace);
      _accountLabelController
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  ValueStream<PersonProvider> get personProvider =>
      _personProviderController.stream;

  Future<void> setPersonProvider(PersonProvider value) async {
    final backup = _personProviderController.value;
    _personProviderController.add(value);
    try {
      if (!await _accountPref.setPersonProvider(value.index)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe(
          "[setPersonProvider] Failed setting preference", e, stackTrace);
      _personProviderController
        ..addError(e, stackTrace)
        ..add(backup);
    }
  }

  AccountPref get raw => _accountPref;

  final Account account;

  final AccountPref _accountPref;
  late final _shareFolderController =
      BehaviorSubject.seeded(_accountPref.getShareFolderOr(""));
  late final _accountLabelController =
      BehaviorSubject.seeded(_accountPref.getAccountLabel());
  late final _personProviderController = BehaviorSubject.seeded(
      PersonProvider.fromValue(_accountPref.getPersonProviderOr()));
}
