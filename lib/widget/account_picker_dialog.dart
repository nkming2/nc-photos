import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:nc_photos/widget/sign_in.dart';

/// A dialog that allows the user to switch between accounts
class AccountPickerDialog extends StatefulWidget {
  AccountPickerDialog({
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
    _accounts = Pref.inst().getAccountsOr([]);
  }

  @override
  build(BuildContext context) {
    final otherAccountOptions = _accounts
        .where((a) => a != widget.account)
        .map((a) => SimpleDialogOption(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: () => _onItemPressed(a),
              child: ListTile(
                dense: true,
                title: Text(a.url),
                subtitle: Text(a.username),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  tooltip: L10n.global().deleteTooltip,
                  onPressed: () => _onRemoveItemPressed(a),
                ),
              ),
            ))
        .toList();
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
    return AppTheme(
      child: SimpleDialog(
        title: ListTile(
          dense: true,
          title: Text(
            widget.account.url,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            widget.account.username,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.edit,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            tooltip: L10n.global().editTooltip,
            onPressed: () => _onEditPressed(),
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.fromSTEB(8, 16, 8, 0),
        contentPadding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 8),
        children: otherAccountOptions + addAccountOptions,
      ),
    );
  }

  void _onItemPressed(Account account) {
    Pref.inst().setCurrentAccountIndex(_accounts.indexOf(account));
    Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (_) => false,
        arguments: HomeArguments(account));
  }

  void _onRemoveItemPressed(Account account) {
    try {
      _removeAccount(account);
      setState(() {
        _accounts = Pref.inst().getAccounts()!;
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

  void _onEditPressed() async {
    try {
      final result = await Navigator.of(context).pushNamed<Account>(
          RootPicker.routeName,
          arguments: RootPickerArguments(widget.account));
      if (result != null) {
        // we've got a good account
        if (result == widget.account) {
          // no changes, do nothing
          _log.fine("[_onEditPressed] No changes");
          Navigator.of(context).pop();
          return;
        }
        final accounts = Pref.inst().getAccounts()!;
        if (accounts.contains(result)) {
          // conflict with another account. This normally won't happen because
          // the app passwords are unique to each entry, but just in case
          Navigator.of(context).pop();
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(L10n.global().editAccountConflictFailureNotification),
            duration: k.snackBarDurationNormal,
          ));
          return;
        }
        accounts[Pref.inst().getCurrentAccountIndex()!] = result;
        Pref.inst()..setAccounts(accounts);
        Navigator.pushNamedAndRemoveUntil(
            context, Home.routeName, (route) => false,
            arguments: HomeArguments(result));
      }
    } catch (e, stacktrace) {
      _log.shout("[_onEditPressed] Exception", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    }
  }

  void _removeAccount(Account account) {
    final currentAccounts = Pref.inst().getAccounts()!;
    final currentAccount =
        currentAccounts[Pref.inst().getCurrentAccountIndex()!];
    final newAccounts =
        currentAccounts.where((element) => element != account).toList();
    final newAccountIndex = newAccounts.indexOf(currentAccount);
    if (newAccountIndex == -1) {
      throw StateError("Active account not found in resulting account list");
    }
    Pref.inst()
      ..setAccounts(newAccounts)
      ..setCurrentAccountIndex(newAccountIndex);
  }

  late List<Account> _accounts;

  static final _log =
      Logger("widget.account_picker_dialog._AccountPickerDialogState");
}
