import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/controller/collections_controller.dart';
import 'package:nc_photos/controller/server_controller.dart';
import 'package:nc_photos/di_container.dart';

class AccountController {
  void setCurrentAccount(Account account) {
    _account = account;
    _collectionsController?.dispose();
    _collectionsController = null;
    _serverController?.dispose();
    _serverController = null;
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

  Account? _account;
  CollectionsController? _collectionsController;
  ServerController? _serverController;
}
