import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/pref_util.dart' as pref_util;
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';

class SignIn extends StatefulWidget {
  static const routeName = "/sign-in";

  const SignIn({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(builder: (context) => _buildContent(context)),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (_isConnecting) {
      return Stack(
        children: const [
          Positioned(
            left: 0,
            right: 0,
            bottom: 64,
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        ],
      );
    } else {
      return SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            L10n.global().signInHeaderText,
                            style: Theme.of(context).textTheme.headline5,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            constraints: const BoxConstraints(
                                maxWidth: AppTheme.widthLimitedContentMaxWidth),
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: _buildForm(context),
                          ),
                        ),
                        if (!platform_k.isWeb) Expanded(child: Container()),
                        Container(
                          constraints: const BoxConstraints(
                              maxWidth: AppTheme.widthLimitedContentMaxWidth),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (!ModalRoute.of(context)!.isFirst)
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(MaterialLocalizations.of(context)
                                      .cancelButtonLabel),
                                )
                              else
                                Container(),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ==
                                      true) {
                                    _connect();
                                  }
                                },
                                child: Text(L10n.global().connectButtonLabel),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Icon(
            Icons.cloud,
            color: Theme.of(context).colorScheme.primary,
            size: 72,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 64,
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<_Scheme>(
                  value: _scheme,
                  items: [_Scheme.http, _Scheme.https]
                      .map((e) => DropdownMenuItem<_Scheme>(
                            value: e,
                            child: Text(e.toValueString()),
                          ))
                      .toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _scheme = newValue!;
                    });
                  },
                  onSaved: (value) {
                    _formValue.scheme = value!.toValueString();
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text("://"),
            ),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: L10n.global().serverAddressInputHint,
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value!.trim().trimRightAny("/").isEmpty) {
                    return L10n.global().serverAddressInputInvalidEmpty;
                  }
                  return null;
                },
                onSaved: (value) {
                  _formValue.address = value!.trim().trimRightAny("/");
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _connect() async {
    _formKey.currentState!.save();
    Uri url = Uri.parse("${_formValue.scheme}://${_formValue.address}");
    _log.info("[_connect] Try connecting with url: $url");
    Account? account = await Navigator.pushNamed<Account>(
        context, Connect.routeName,
        arguments: ConnectArguments(url));
    if (account == null) {
      // connection failed
      return;
    }
    account = await Navigator.pushNamed<Account>(context, RootPicker.routeName,
        arguments: RootPickerArguments(account));
    if (account == null) {
      // ???
      return;
    }
    // we've got a good account
    setState(() {
      _isConnecting = true;
    });
    try {
      await _persistAccount(account);
      unawaited(
        Navigator.pushNamedAndRemoveUntil(
            context, Home.routeName, (route) => false,
            arguments: HomeArguments(account)),
      );
    } catch (_) {
      setState(() {
        _isConnecting = false;
      });
      rethrow;
    }
  }

  Future<void> _persistAccount(Account account) async {
    final c = KiwiContainer().resolve<DiContainer>();
    await c.sqliteDb.use((db) async {
      await db.insertAccountOf(account);
    });
    // only signing in with app password would trigger distinct
    final accounts = (Pref().getAccounts3Or([])..add(account)).distinct();
    try {
      AccountPref.setGlobalInstance(
          account, await pref_util.loadAccountPref(account));
    } catch (e, stackTrace) {
      _log.shout("[_connect] Failed reading pref for account: $account", e,
          stackTrace);
    }
    unawaited(Pref().setAccounts3(accounts));
    unawaited(Pref().setCurrentAccountIndex(accounts.indexOf(account)));
  }

  final _formKey = GlobalKey<FormState>();
  var _scheme = _Scheme.https;
  var _isConnecting = false;

  final _formValue = _FormValue();

  static final _log = Logger("widget.sign_in._SignInState");
}

enum _Scheme {
  http,
  https,
}

extension on _Scheme {
  String toValueString() {
    switch (this) {
      case _Scheme.http:
        return "http";

      case _Scheme.https:
        return "https";

      default:
        throw StateError("Unknown value: $this");
    }
  }
}

class _FormValue {
  late String scheme;
  late String address;
}
