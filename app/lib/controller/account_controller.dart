import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/account_pref_controller.dart';
import 'package:nc_photos/controller/collections_controller.dart';
import 'package:nc_photos/controller/persons_controller.dart';
import 'package:nc_photos/controller/server_controller.dart';
import 'package:nc_photos/di_container.dart';

class AccountController {
  void setCurrentAccount(Account account) {
    _account = account;
    _collectionsController?.dispose();
    _collectionsController = null;
    _serverController?.dispose();
    _serverController = null;
    _accountPrefController?.dispose();
    _accountPrefController = null;
    _personsController?.dispose();
    _personsController = null;
  }

  Account get account => _account!;

  CollectionsController get collectionsController =>
      _collectionsController ??= CollectionsController(
        KiwiContainer().resolve<DiContainer>(),
        account: _account!,
        serverController: serverController,
      );

  ServerController get serverController =>
      _serverController ??= ServerController(
        account: _account!,
      );

  AccountPrefController get accountPrefController =>
      _accountPrefController ??= AccountPrefController(
        account: _account!,
      );

  PersonsController get personsController =>
      _personsController ??= PersonsController(
        KiwiContainer().resolve<DiContainer>(),
        account: _account!,
        accountPrefController: accountPrefController,
      );

  Account? _account;
  CollectionsController? _collectionsController;
  ServerController? _serverController;
  AccountPrefController? _accountPrefController;
  PersonsController? _personsController;
}
