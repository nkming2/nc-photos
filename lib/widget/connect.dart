import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/app_password_exchange.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/self_signed_cert_manager.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';

class ConnectArguments {
  ConnectArguments(this.account);

  final Account account;
}

class Connect extends StatefulWidget {
  static const routeName = "/connect";

  static Route buildRoute(ConnectArguments args) => MaterialPageRoute<Account>(
        builder: (context) => Connect.fromArgs(args),
      );

  Connect({
    Key? key,
    required this.account,
  }) : super(key: key);

  Connect.fromArgs(ConnectArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _ConnectState();

  final Account account;
}

class _ConnectState extends State<Connect> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body:
            BlocListener<AppPasswordExchangeBloc, AppPasswordExchangeBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: Builder(builder: (context) => _buildContent(context)),
        ),
      ),
    );
  }

  void _initBloc() {
    _log.info("[_initBloc] Initialize bloc");
    _connect();
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud,
              size: 128,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              L10n.of(context).connectingToServer(widget.account.url),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline6,
            )
          ],
        ),
      ),
    );
  }

  void _onStateChange(
      BuildContext context, AppPasswordExchangeBlocState state) {
    if (state is AppPasswordExchangeBlocSuccess) {
      final newAccount = widget.account.copyWith(password: state.password);
      _log.info("[_onStateChange] Account is good: $newAccount");
      Navigator.of(context).pop(newAccount);
    } else if (state is AppPasswordExchangeBlocFailure) {
      if (features.isSupportSelfSignedCert &&
          state.exception is HandshakeException) {
        _onSelfSignedCert(context);
      } else if (state.exception is ApiException &&
          (state.exception as ApiException).response.statusCode == 401) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.of(context).errorWrongPassword),
          duration: k.snackBarDurationNormal,
        ));
        Navigator.of(context).pop(null);
      } else {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception, context)),
          duration: k.snackBarDurationNormal,
        ));
        Navigator.of(context).pop(null);
      }
    }
  }

  void _onSelfSignedCert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).serverCertErrorDialogTitle),
        content: Text(L10n.of(context).serverCertErrorDialogContent),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(MaterialLocalizations.of(context).closeButtonLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(L10n.of(context).advancedButtonLabel),
          ),
        ],
      ),
    ).then((value) {
      if (value != true) {
        Navigator.of(context).pop(null);
        return;
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).whitelistCertDialogTitle),
          content: Text(L10n.of(context).whitelistCertDialogContent(
              SelfSignedCertManager().getLastBadCertHost(),
              SelfSignedCertManager().getLastBadCertFingerprint())),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(L10n.of(context).whitelistCertButtonLabel),
            ),
          ],
        ),
      ).then((value) {
        if (value != true) {
          Navigator.of(context).pop(null);
          return;
        }
        SelfSignedCertManager().whitelistLastBadCert().then((value) {
          Navigator.of(context).pop(null);
        });
      });
    });
  }

  void _connect() {
    _bloc.add(AppPasswordExchangeBlocConnect(widget.account));
  }

  final _bloc = AppPasswordExchangeBloc();

  static final _log = Logger("widget.connect._ConnectState");
}
