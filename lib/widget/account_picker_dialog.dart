import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/sign_in.dart';

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
                    icon: const Icon(Icons.close),
                    onPressed: () => _onRemoveItemPressed(a)),
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
          child: const Center(
            child: const Icon(Icons.add, color: Colors.black54),
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
}
