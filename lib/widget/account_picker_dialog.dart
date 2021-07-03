import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
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
    Key key,
    @required this.account,
  }) : super(key: key);

  @override
  createState() => _AccountPickerDialogState();

  final Account account;
}

class _AccountPickerDialogState extends State<AccountPickerDialog> {
  @override
  initState() {
    super.initState();
    _accounts = Pref.inst().getAccounts([]);
  }

  @override
  build(BuildContext context) {
    final otherAccountOptions = _accounts
        .where((a) => a != widget.account)
        .map((a) => SimpleDialogOption(
              onPressed: () => _onItemPressed(a),
              child: ListTile(
                title: Text(a.url),
                subtitle: Text(a.username),
                trailing: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.getSecondaryTextColor(context),
                  ),
                  tooltip: AppLocalizations.of(context).deleteTooltip,
                  onPressed: () => _onRemoveItemPressed(a),
                ),
              ),
            ))
        .toList();
    final addAccountOptions = [
      SimpleDialogOption(
        onPressed: () {
          Navigator.of(context)
            ..pop()
            ..pushNamed(SignIn.routeName);
        },
        child: Tooltip(
          message: AppLocalizations.of(context).addServerTooltip,
          child: Center(
            child: Icon(
              Icons.add,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      ),
    ];
    return SimpleDialog(
      title: ListTile(
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
          tooltip: AppLocalizations.of(context).editTooltip,
          onPressed: () => _onEditPressed(),
        ),
      ),
      children: otherAccountOptions + addAccountOptions,
    );
  }

  void _onItemPressed(Account account) {
    Pref.inst().setCurrentAccountIndex(_accounts.indexOf(account));
    Navigator.of(context).pushNamedAndRemoveUntil(Home.routeName, (_) => false,
        arguments: HomeArguments(account));
  }

  void _onRemoveItemPressed(Account account) {
    _removeAccount(account);
    setState(() {
      _accounts = Pref.inst().getAccounts([]);
    });
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)
          .removeServerSuccessNotification(account.url)),
      duration: k.snackBarDurationNormal,
    ));
  }

  void _onEditPressed() async {
    try {
      final result = await Navigator.of(context).pushNamed(RootPicker.routeName,
          arguments: RootPickerArguments(widget.account));
      if (result != null) {
        // we've got a good account
        if (result == widget.account) {
          // no changes, do nothing
          _log.fine("[_onEditPressed] No changes");
          Navigator.of(context).pop();
          return;
        }
        final accounts = Pref.inst().getAccounts([]);
        if (accounts.contains(result)) {
          // conflict with another account. This normally won't happen because
          // the app passwords are unique to each entry, but just in case
          Navigator.of(context).pop();
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)
                .editAccountConflictFailureNotification),
            duration: k.snackBarDurationNormal,
          ));
          return;
        }
        accounts[Pref.inst().getCurrentAccountIndex()] = result;
        Pref.inst()..setAccounts(accounts);
        Navigator.pushNamedAndRemoveUntil(
            context, Home.routeName, (route) => false,
            arguments: HomeArguments(result));
      }
    } catch (e, stacktrace) {
      _log.shout("[_onEditPressed] Exception", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e, context)),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    }
  }

  void _removeAccount(Account account) {
    final currentAccounts = Pref.inst().getAccounts([]);
    final currentAccount =
        currentAccounts[Pref.inst().getCurrentAccountIndex()];
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

  List<Account> _accounts;

  static final _log =
      Logger("widget.account_picker_dialog._AccountPickerDialogState");
}
