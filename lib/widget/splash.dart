import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/changelog.dart' as changelog;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/sign_in.dart';

class Splash extends StatefulWidget {
  static const routeName = "/splash";

  Splash({Key key}) : super(key: key);

  @override
  createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
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
              color: AppTheme.getCloudIconColor(context),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).appTitle,
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
    final lastVersion = Pref.inst().getLastVersion(k.version);
    return lastVersion < k.version;
  }

  void _handleUpgrade() {
    final lastVersion = Pref.inst().getLastVersion(k.version);
    // ...

    final change = _gatherChangelog(lastVersion);
    if (change.isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).changelogTitle),
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
      ).whenComplete(() {
        _initTimedExit();
        Pref.inst().setLastVersion(k.version);
      });
    } else {
      _initTimedExit();
      Pref.inst().setLastVersion(k.version);
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
          .where((element) => element != null)
          .join("\n\n");
    } catch (e, stacktrace) {
      _log.severe("[_gatherChangelog] Failed", e, stacktrace);
      return "";
    }
  }

  static final _log = Logger("widget.splash._SplashState");
}
