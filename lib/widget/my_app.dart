import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_viewer.dart';
import 'package:nc_photos/widget/archive_viewer.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/sign_in.dart';
import 'package:nc_photos/widget/splash.dart';
import 'package:nc_photos/widget/viewer.dart';

class MyApp extends StatefulWidget {
  @override
  createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> implements SnackBarHandler {
  @override
  void initState() {
    super.initState();
    SnackBarManager().registerHandler(this);
    _themeChangedListener =
        AppEventListener<ThemeChangedEvent>(_onThemeChangedEvent)..begin();
    _langChangedListener =
        AppEventListener<LanguageChangedEvent>(_onLangChangedEvent)..begin();
  }

  @override
  build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode: Pref.inst().isDarkTheme() ? ThemeMode.dark : ThemeMode.light,
      initialRoute: Splash.routeName,
      onGenerateRoute: _onGenerateRoute,
      scaffoldMessengerKey: _scaffoldMessengerKey,
      locale: language_util.getSelectedLocale(context),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
    );
  }

  @override
  void dispose() {
    super.dispose();
    SnackBarManager().unregisterHandler(this);
    _themeChangedListener.end();
    _langChangedListener.end();
  }

  @override
  showSnackBar(SnackBar snackBar) =>
      _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);

  ThemeData _getLightTheme() => ThemeData(
        brightness: Brightness.light,
        primarySwatch: AppTheme.primarySwatchLight,
      );

  ThemeData _getDarkTheme() => ThemeData(
        brightness: Brightness.dark,
        primarySwatch: AppTheme.primarySwatchDark,
      );

  Map<String, WidgetBuilder> _getRouter() => {
        Setup.routeName: (context) => Setup(),
        SignIn.routeName: (context) => SignIn(),
        Splash.routeName: (context) => Splash(),
      };

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    _log.info("[_onGenerateRoute] Route: ${settings.name}");
    Route<dynamic> route;
    route ??= _handleBasicRoute(settings);
    route ??= _handleViewerRoute(settings);
    route ??= _handleConnectRoute(settings);
    route ??= _handleHomeRoute(settings);
    route ??= _handleRootPickerRoute(settings);
    route ??= _handleAlbumViewerRoute(settings);
    route ??= _handleSettingsRoute(settings);
    route ??= _handleArchiveViewerRoute(settings);
    return route;
  }

  void _onThemeChangedEvent(ThemeChangedEvent ev) {
    setState(() {});
  }

  void _onLangChangedEvent(LanguageChangedEvent ev) {
    setState(() {});
  }

  Route<dynamic> _handleBasicRoute(RouteSettings settings) {
    for (final e in _getRouter().entries) {
      if (e.key == settings.name) {
        return MaterialPageRoute(
          builder: e.value,
        );
      }
    }
    return null;
  }

  Route<dynamic> _handleViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == Viewer.routeName && settings.arguments != null) {
        final ViewerArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => Viewer.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleConnectRoute(RouteSettings settings) {
    try {
      if (settings.name == Connect.routeName && settings.arguments != null) {
        final ConnectArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => Connect.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleConnectRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleHomeRoute(RouteSettings settings) {
    try {
      if (settings.name == Home.routeName && settings.arguments != null) {
        final HomeArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => Home.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleHomeRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleRootPickerRoute(RouteSettings settings) {
    try {
      if (settings.name == RootPicker.routeName && settings.arguments != null) {
        final RootPickerArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => RootPicker.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleRootPickerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleAlbumViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumViewer.routeName &&
          settings.arguments != null) {
        final AlbumViewerArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => AlbumViewer.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleAlbumViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleSettingsRoute(RouteSettings settings) {
    try {
      if (settings.name == Settings.routeName && settings.arguments != null) {
        final SettingsArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => Settings.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleSettingsRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic> _handleArchiveViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == ArchiveViewer.routeName &&
          settings.arguments != null) {
        final ArchiveViewerArguments args = settings.arguments;
        return MaterialPageRoute(
          builder: (context) => ArchiveViewer.fromArgs(args),
        );
      }
    } catch (e) {
      _log.severe("[_handleArchiveViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  AppEventListener<ThemeChangedEvent> _themeChangedListener;
  AppEventListener<LanguageChangedEvent> _langChangedListener;

  static final _log = Logger("widget.my_app.MyAppState");
}
