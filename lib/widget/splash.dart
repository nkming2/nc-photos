import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/changelog.dart' as changelog;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/compat/v29.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/sign_in.dart';

class Splash extends StatefulWidget {
  static const routeName = "/splash";

  const Splash({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
      if (_shouldUpgrade()) {
        _handleUpgrade();
      } else {
        _initTimedExit();
      }
    });
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: Builder(builder: (context) => _buildContent(context)),
      ),
    );
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
              size: 96,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              L10n.global().appTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headline4,
            )
          ],
        ),
      ),
    );
  }

  void _initTimedExit() {
    Future.delayed(const Duration(seconds: 1)).then((_) {
      final account = Pref.inst().getCurrentAccount();
      if (isNeedSetup()) {
        Navigator.pushReplacementNamed(context, Setup.routeName);
      } else if (account == null) {
        Navigator.pushReplacementNamed(context, SignIn.routeName);
      } else {
        Navigator.pushReplacementNamed(context, Home.routeName,
            arguments: HomeArguments(account));
      }
    });
  }

  bool _shouldUpgrade() {
    final lastVersion = Pref.inst().getLastVersionOr(k.version);
    return lastVersion < k.version;
  }

  void _handleUpgrade() async {
    try {
      final lastVersion = Pref.inst().getLastVersionOr(k.version);
      await _upgrade(lastVersion);

      final change = _gatherChangelog(lastVersion);
      if (change.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(L10n.global().changelogTitle),
            content: SingleChildScrollView(
              child: Text(change),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              )
            ],
          ),
        );
      }
    } finally {
      _initTimedExit();
      Pref.inst().setLastVersion(k.version);
    }
  }

  Future<void> _upgrade(int lastVersion) async {
    if (lastVersion < 290) {
      await _upgrade29(lastVersion);
    }
  }

  Future<void> _upgrade29(int lastVersion) async {
    await _peformUpgrade(() async {
      try {
        _log.info("[_upgrade29] clearDefaultCache");
        await CompatV29.clearDefaultCache();
      } catch (e, stackTrace) {
        _log.shout(
            "[_upgrade29] Failed while clearDefaultCache", e, stackTrace);
        // just leave the cache then
      }
    });
  }

  Future<void> _peformUpgrade(FutureOr<void> Function() fn) async {
    showDialog(
        context: context,
        builder: (_) => ProcessingDialog(
              text: L10n.global().genericProcessingDialogContent,
            ));
    try {
      await fn();
    } finally {
      Navigator.of(context).pop();
    }
  }

  String _gatherChangelog(int from) {
    if (from < 100) {
      from *= 10;
    }
    final fromMajor = from ~/ 10;
    try {
      return changelog.contents
          .sublist(fromMajor)
          .reversed
          .whereType<String>()
          .map((e) => e.trim())
          .join("\n\n");
    } catch (e, stacktrace) {
      _log.severe("[_gatherChangelog] Failed", e, stacktrace);
      return "";
    }
  }

  static final _log = Logger("widget.splash._SplashState");
}
