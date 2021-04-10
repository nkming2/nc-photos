import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/sign_in.dart';

/// A useless widget
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
              color: Theme.of(context).primaryColor,
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
}
