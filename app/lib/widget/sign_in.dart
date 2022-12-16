import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/legacy/sign_in.dart' as legacy;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/pref_util.dart' as pref_util;
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:np_codegen/np_codegen.dart';

part 'sign_in.g.dart';

class SignIn extends StatefulWidget {
  static const routeName = "/sign-in";

  const SignIn({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _SignInState();
}

@npLog
class _SignInState extends State<SignIn> {
  @override
  build(BuildContext context) {
    return Theme(
      data: buildDarkTheme().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: Colors.white,
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _SingInBackground(),
          Scaffold(
            body: Builder(builder: (context) => _buildContent(context)),
          ),
        ],
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
      return Form(
        key: _formKey,
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              maxWidth: Theme.of(context).widthLimitedContentMaxWidth,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: _SignInBody(
                        onSchemeSaved: (scheme) {
                          _formValue.scheme = scheme;
                        },
                        onServerUrlSaved: (url) {
                          _formValue.address = url;
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          if (_formKey.currentState?.validate() == true) {
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
      );
    }
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
  var _isConnecting = false;

  final _formValue = _FormValue();
}

/// A nice background that matches Nextcloud without breaking any copyright law
class _SingInBackground extends StatelessWidget {
  const _SingInBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: Theme.of(context).nextcloudBlue),
        const Positioned(
          bottom: 60,
          left: -200,
          child: Opacity(
            opacity: .22,
            child: Icon(
              Icons.circle_outlined,
              color: Colors.white,
              size: 340,
            ),
          ),
        ),
        const Positioned(
          top: -120,
          left: -180,
          right: 0,
          child: Opacity(
            opacity: .1,
            child: Icon(
              Icons.circle_outlined,
              color: Colors.white,
              size: 620,
            ),
          ),
        ),
        const Positioned(
          bottom: -50,
          right: -120,
          child: Opacity(
            opacity: .27,
            child: Icon(
              Icons.circle_outlined,
              color: Colors.white,
              size: 400,
            ),
          ),
        ),
      ],
    );
  }
}

class _SignInBody extends StatelessWidget {
  const _SignInBody({
    this.onSchemeSaved,
    this.onServerUrlSaved,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.global().signInHeaderText2,
            style: Theme.of(context).textTheme.displayLarge!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w100,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 64,
                child: _SchemeDropdown(
                  onSaved: onSchemeSaved,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text("://"),
              ),
              Expanded(
                child: _ServerUrlInput(
                  onSaved: onServerUrlSaved,
                ),
              ),
            ],
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Navigator.pushReplacementNamed(
                    context, legacy.SignIn.routeName);
              },
              child: const Text(
                "Legacy sign in",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }

  final void Function(String scheme)? onSchemeSaved;
  final void Function(String url)? onServerUrlSaved;
}

enum _Scheme {
  http,
  https;

  String toValueString() {
    switch (this) {
      case http:
        return "http";

      case https:
        return "https";
    }
  }
}

class _SchemeDropdown extends StatefulWidget {
  const _SchemeDropdown({
    this.onSaved,
  });

  @override
  State<StatefulWidget> createState() => _SchemeDropdownState();

  final void Function(String scheme)? onSaved;
}

class _SchemeDropdownState extends State<_SchemeDropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButtonFormField<_Scheme>(
        value: _scheme,
        items: _Scheme.values
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
          widget.onSaved?.call(value!.toValueString());
        },
      ),
    );
  }

  var _scheme = _Scheme.https;
}

class _ServerUrlInput extends StatelessWidget {
  const _ServerUrlInput({
    this.onSaved,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
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
        onSaved?.call(value!.trim().trimRightAny("/"));
      },
    );
  }

  final void Function(String url)? onSaved;
}

class _FormValue {
  late String scheme;
  late String address;
}
