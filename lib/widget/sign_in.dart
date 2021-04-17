import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/list_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/string_extension.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';

class SignIn extends StatefulWidget {
  static const routeName = "/sign-in";

  SignIn({Key key}) : super(key: key);

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
                          AppLocalizations.of(context).signInHeaderText,
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
                      Expanded(child: Container()),
                      Container(
                        constraints: const BoxConstraints(
                            maxWidth: AppTheme.widthLimitedContentMaxWidth),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!ModalRoute.of(context).isFirst)
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
                                if (_formKey.currentState.validate()) {
                                  _connect();
                                }
                              },
                              child: Text(AppLocalizations.of(context)
                                  .connectButtonLabel),
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
            color: AppTheme.getCloudIconColor(context),
            size: 72,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Container(
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
                      _scheme = newValue;
                    });
                  },
                  onSaved: (value) {
                    _formValue.scheme = value.toValueString();
                  },
                ),
              ),
            ),
            const Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: const Text("://"),
            ),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).serverAddressInputHint,
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value.trim().trimRightAny("/").isEmpty) {
                    return AppLocalizations.of(context)
                        .serverAddressInputInvalidEmpty;
                  }
                  return null;
                },
                onSaved: (value) {
                  _formValue.address = value.trim().trimRightAny("/");
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).usernameInputHint,
          ),
          validator: (value) {
            if (value.trim().isEmpty) {
              return AppLocalizations.of(context).usernameInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _formValue.username = value;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).passwordInputHint,
          ),
          obscureText: true,
          validator: (value) {
            if (value.trim().isEmpty) {
              return AppLocalizations.of(context).passwordInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _formValue.password = value;
          },
        ),
      ],
    );
  }

  void _connect() {
    _formKey.currentState.save();
    final account = Account(_formValue.scheme, _formValue.address,
        _formValue.username, _formValue.password, [""]);
    _log.info("[_connect] Try connecting with account: $account");
    Navigator.pushNamed(context, Connect.routeName,
            arguments: ConnectArguments(account))
        .then((result) {
      return result != null
          ? Navigator.pushNamed(context, RootPicker.routeName,
              arguments: RootPickerArguments(result))
          : null;
    }).then((result) {
      if (result != null) {
        // we've got a good account
        final accounts = (Pref.inst().getAccounts([])..add(result)).distinct();
        Pref.inst()
          ..setAccounts(accounts)
          ..setCurrentAccountIndex(accounts.indexOf(result));
        Navigator.pushNamedAndRemoveUntil(
            context, Home.routeName, (route) => false,
            arguments: HomeArguments(result));
      }
    });
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
  String scheme;
  String address;
  String username;
  String password;
}
