import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
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

  ValueStream<bool> get isEnableFaceRecognitionApp =>
      _enableFaceRecognitionAppController.stream;

  Future<void> setEnableFaceRecognitionApp(bool value) async {
    final backup = _enableFaceRecognitionAppController.value;
    _enableFaceRecognitionAppController.add(value);
    try {
      if (!await _accountPref.setEnableFaceRecognitionApp(value)) {
        throw StateError("Unknown error");
      }
    } catch (e, stackTrace) {
      _log.severe("[setEnableFaceRecognitionApp] Failed setting preference", e,
          stackTrace);
      _enableFaceRecognitionAppController
        ..addError(e, stackTrace)
        ..add(backup);
    }
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

  AccountPref get raw => _accountPref;

  final Account account;

  final AccountPref _accountPref;
  late final _enableFaceRecognitionAppController =
      BehaviorSubject.seeded(_accountPref.isEnableFaceRecognitionAppOr(true));
  late final _shareFolderController =
      BehaviorSubject.seeded(_accountPref.getShareFolderOr(""));
  late final _accountLabelController =
      BehaviorSubject.seeded(_accountPref.getAccountLabel());
}
