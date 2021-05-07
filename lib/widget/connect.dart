import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/app_password_exchange.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';

class ConnectArguments {
  ConnectArguments(this.account);

  final Account account;
}

class Connect extends StatefulWidget {
  static const routeName = "/connect";

  Connect({
    Key key,
    @required this.account,
  }) : super(key: key);

  Connect.fromArgs(ConnectArguments args, {Key key})
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
              color: AppTheme.getCloudIconColor(context),
            ),
            Text(
              AppLocalizations.of(context)
                  .connectingToServer(widget.account.url),
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
      if (state.exception is ApiException &&
          (state.exception as ApiException).response.statusCode == 401) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context).errorWrongPassword),
          duration: k.snackBarDurationNormal,
        ));
      } else {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception, context)),
          duration: k.snackBarDurationNormal,
        ));
      }
      Navigator.of(context).pop(null);
    }
  }

  void _connect() {
    _bloc.add(AppPasswordExchangeBlocConnect(widget.account));
  }

  final _bloc = AppPasswordExchangeBloc();

  static final _log = Logger("widget.connect._ConnectState");
}
