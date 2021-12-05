import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/help_utils.dart' as help_utils;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/pref_util.dart' as pref_util;
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
                      Container(
                        alignment: AlignmentDirectional.centerStart,
                        constraints: const BoxConstraints(
                            maxWidth: AppTheme.widthLimitedContentMaxWidth),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: InkWell(
                          onTap: () {
                            launch(help_utils.twoFactorAuthUrl);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.help_outline, size: 16),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(L10n.global().signIn2faHintText),
                                ),
                              ],
                            ),
                          ),
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
            ),
          );
        },
      ),
    );
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
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: L10n.global().usernameInputHint,
          ),
          validator: (value) {
            if (value!.trim().isEmpty) {
              return L10n.global().usernameInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _formValue.username = value!;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: L10n.global().passwordInputHint,
          ),
          obscureText: true,
          validator: (value) {
            if (value!.trim().isEmpty) {
              return L10n.global().passwordInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _formValue.password = value!;
          },
        ),
      ],
    );
  }

  Future<void> _connect() async {
    _formKey.currentState!.save();
    Account? account = Account(
      Account.newId(),
      _formValue.scheme,
      _formValue.address,
      _formValue.username.toCi(),
      _formValue.password,
      [""],
    );
    _log.info("[_connect] Try connecting with account: $account");
    account = await Navigator.pushNamed<Account>(context, Connect.routeName,
        arguments: ConnectArguments(account));
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
    // only signing in with app password would trigger distinct
    final accounts = (Pref().getAccounts3Or([])..add(account)).distinct();
    try {
      AccountPref.setGlobalInstance(
          account, await pref_util.loadAccountPref(account));
    } catch (e, stackTrace) {
      _log.shout("[_connect] Failed reading pref for account: $account", e,
          stackTrace);
    }
    Pref()
      ..setAccounts3(accounts)
      ..setCurrentAccountIndex(accounts.indexOf(account));
    Navigator.pushNamedAndRemoveUntil(context, Home.routeName, (route) => false,
        arguments: HomeArguments(account));
  }

  final _formKey = GlobalKey<FormState>();
  var _scheme = _Scheme.https;

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
  late String username;
  late String password;
}
