import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/sign_in.dart';

/// A dialog that allows the user to switch between accounts
class AccountPickerDialog extends StatefulWidget {
  const AccountPickerDialog({
    Key? key,
    required this.account,
  }) : super(key: key);

  @override
  createState() => _AccountPickerDialogState();

  final Account account;
}

class _AccountPickerDialogState extends State<AccountPickerDialog> {
  @override
  initState() {
    super.initState();
    _accounts = Pref().getAccounts3Or([]);
  }

  @override
  build(BuildContext context) {
    final otherAccountOptions =
        _accounts.where((a) => a != widget.account).map((a) {
      final label = AccountPref.of(a).getAccountLabel();
      return SimpleDialogOption(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        onPressed: () => _onItemPressed(a),
        child: ListTile(
          dense: true,
          title: Text(label ?? a.url),
          subtitle: label == null ? Text(a.username2) : null,
          trailing: IconButton(
            icon: Icon(
              Icons.close,
              color: AppTheme.getUnfocusedIconColor(context),
            ),
            tooltip: L10n.global().deleteTooltip,
            onPressed: () => _onRemoveItemPressed(a),
          ),
        ),
      );
    }).toList();
    final addAccountOptions = [
      SimpleDialogOption(
        padding: const EdgeInsets.all(8),
        onPressed: () {
          Navigator.of(context)
            ..pop()
            ..pushNamed(SignIn.routeName);
        },
        child: Tooltip(
          message: L10n.global().addServerTooltip,
          child: Center(
            child: Icon(
              Icons.add,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      ),
    ];
    final accountLabel = AccountPref.of(widget.account).getAccountLabel();
    return AppTheme(
      child: SimpleDialog(
        title: ListTile(
          dense: true,
          title: Text(
            accountLabel ?? widget.account.url,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: accountLabel == null
              ? Text(
                  widget.account.username2,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )
              : null,
          trailing: IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppTheme.getUnfocusedIconColor(context),
            ),
            tooltip: L10n.global().settingsAccountPageTitle,
            onPressed: _onEditPressed,
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 0),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 8),
        children: otherAccountOptions + addAccountOptions,
      ),
    );
  }

  void _onItemPressed(Account account) {
    Pref().setCurrentAccountIndex(_accounts.indexOf(account));
    Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (_) => false,
        arguments: HomeArguments(account));
  }

  Future<void> _onRemoveItemPressed(Account account) async {
    try {
      await _removeAccount(account);
      setState(() {
        _accounts = Pref().getAccounts3()!;
      });
      SnackBarManager().showSnackBar(SnackBar(
        content:
            Text(L10n.global().removeServerSuccessNotification(account.url)),
        duration: k.snackBarDurationNormal,
      ));
    } catch (e) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onEditPressed() {
    Navigator.of(context)
      ..pop()
      ..pushNamed(AccountSettingsWidget.routeName,
          arguments: AccountSettingsWidgetArguments(widget.account));
  }

  Future<void> _removeAccount(Account account) async {
    _log.info("[_removeAccount] Remove account: $account");
    final accounts = Pref().getAccounts3()!;
    final currentAccount = accounts[Pref().getCurrentAccountIndex()!];
    accounts.remove(account);
    final newAccountIndex = accounts.indexOf(currentAccount);
    if (newAccountIndex == -1) {
      throw StateError("Active account not found in resulting account list");
    }
    try {
      await AccountPref.of(account).provider.clear();
    } catch (e, stackTrace) {
      _log.shout(
          "[_removeAccount] Failed while removing account pref", e, stackTrace);
    }
    Pref()
      ..setAccounts3(accounts)
      ..setCurrentAccountIndex(newAccountIndex);

    // check if the same account (server + userId) still exists in known
    // accounts
    if (!accounts
        .any((a) => a.url == account.url && a.userId == account.userId)) {
      // account removed, clear cache db
      await _removeAccountFromDb(account);
    }
  }

  Future<void> _removeAccountFromDb(Account account) async {
    try {
      final c = KiwiContainer().resolve<DiContainer>();
      await c.sqliteDb.use((db) async {
        await db.deleteAccountOf(account);
      });
    } catch (e, stackTrace) {
      _log.shout("[_removeAccountFromDb] Failed while removing account from db",
          e, stackTrace);
    }
  }

  late List<Account> _accounts;

  static final _log =
      Logger("widget.account_picker_dialog._AccountPickerDialogState");
}
