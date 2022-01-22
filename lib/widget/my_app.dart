import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_browser.dart';
import 'package:nc_photos/widget/album_dir_picker.dart';
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/album_picker.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/people_browser.dart';
import 'package:nc_photos/widget/person_browser.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:nc_photos/widget/setup.dart';
import 'package:nc_photos/widget/share_folder_picker.dart';
import 'package:nc_photos/widget/shared_file_viewer.dart';
import 'package:nc_photos/widget/sharing_browser.dart';
import 'package:nc_photos/widget/sign_in.dart';
import 'package:nc_photos/widget/slideshow_viewer.dart';
import 'package:nc_photos/widget/smart_album_browser.dart';
import 'package:nc_photos/widget/splash.dart';
import 'package:nc_photos/widget/trashbin_browser.dart';
import 'package:nc_photos/widget/trashbin_viewer.dart';
import 'package:nc_photos/widget/viewer.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _MyAppState();

  static RouteObserver get routeObserver => _routeObserver;

  static BuildContext get globalContext => _globalContext;

  static final _routeObserver = RouteObserver<PageRoute>();
  static late BuildContext _globalContext;
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
    final ThemeMode themeMode;
    if (Pref().isFollowSystemThemeOr(false)) {
      themeMode = ThemeMode.system;
    } else {
      themeMode =
          Pref().isDarkThemeOr(false) ? ThemeMode.dark : ThemeMode.light;
    }
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: _getLightTheme(),
      darkTheme: _getDarkTheme(),
      themeMode: themeMode,
      initialRoute: Splash.routeName,
      onGenerateRoute: _onGenerateRoute,
      navigatorObservers: <NavigatorObserver>[MyApp.routeObserver],
      scaffoldMessengerKey: _scaffoldMessengerKey,
      locale: language_util.getSelectedLocale(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const <Locale>[
        // the order here doesn't matter, except for the first one, which must
        // be en
        Locale("en"),
        Locale("el"),
        Locale("es"),
        Locale("fr"),
        Locale("ru"),
        Locale("de"),
        Locale("cs"),
        Locale("fi"),
        Locale("pl"),
      ],
      builder: (context, child) {
        MyApp._globalContext = context;
        return child!;
      },
      debugShowCheckedModeBanner: false,
      scrollBehavior: const _MyScrollBehavior(),
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
        Setup.routeName: (context) => const Setup(),
        SignIn.routeName: (context) => const SignIn(),
        Splash.routeName: (context) => const Splash(),
      };

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    _log.info("[_onGenerateRoute] Route: ${settings.name}");
    Route<dynamic>? route;
    route ??= _handleBasicRoute(settings);
    route ??= _handleViewerRoute(settings);
    route ??= _handleConnectRoute(settings);
    route ??= _handleHomeRoute(settings);
    route ??= _handleRootPickerRoute(settings);
    route ??= _handleAlbumBrowserRoute(settings);
    route ??= _handleSettingsRoute(settings);
    route ??= _handleArchiveBrowserRoute(settings);
    route ??= _handleDynamicAlbumBrowserRoute(settings);
    route ??= _handleAlbumDirPickerRoute(settings);
    route ??= _handleAlbumImporterRoute(settings);
    route ??= _handleTrashbinBrowserRoute(settings);
    route ??= _handleTrashbinViewerRoute(settings);
    route ??= _handlePeopleBrowserRoute(settings);
    route ??= _handlePersonBrowserRoute(settings);
    route ??= _handleSlideshowViewerRoute(settings);
    route ??= _handleSharingBrowserRoute(settings);
    route ??= _handleSharedFileViewerRoute(settings);
    route ??= _handleAlbumShareOutlierBrowserRoute(settings);
    route ??= _handleAccountSettingsRoute(settings);
    route ??= _handleShareFolderPickerRoute(settings);
    route ??= _handleAlbumPickerRoute(settings);
    route ??= _handleSmartAlbumBrowserRoute(settings);
    return route;
  }

  void _onThemeChangedEvent(ThemeChangedEvent ev) {
    setState(() {});
  }

  void _onLangChangedEvent(LanguageChangedEvent ev) {
    setState(() {});
  }

  Route<dynamic>? _handleBasicRoute(RouteSettings settings) {
    for (final e in _getRouter().entries) {
      if (e.key == settings.name) {
        return MaterialPageRoute(
          builder: e.value,
        );
      }
    }
    return null;
  }

  Route<dynamic>? _handleViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == Viewer.routeName && settings.arguments != null) {
        final args = settings.arguments as ViewerArguments;
        return Viewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleConnectRoute(RouteSettings settings) {
    try {
      if (settings.name == Connect.routeName && settings.arguments != null) {
        final args = settings.arguments as ConnectArguments;
        return Connect.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleConnectRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleHomeRoute(RouteSettings settings) {
    try {
      if (settings.name == Home.routeName && settings.arguments != null) {
        final args = settings.arguments as HomeArguments;
        return Home.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleHomeRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleRootPickerRoute(RouteSettings settings) {
    try {
      if (settings.name == RootPicker.routeName && settings.arguments != null) {
        final args = settings.arguments as RootPickerArguments;
        return RootPicker.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleRootPickerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleAlbumBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AlbumBrowserArguments;
        return AlbumBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleAlbumBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleSettingsRoute(RouteSettings settings) {
    try {
      if (settings.name == Settings.routeName && settings.arguments != null) {
        final args = settings.arguments as SettingsArguments;
        return Settings.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleSettingsRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleArchiveBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == ArchiveBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as ArchiveBrowserArguments;
        return ArchiveBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleArchiveBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleDynamicAlbumBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == DynamicAlbumBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as DynamicAlbumBrowserArguments;
        return DynamicAlbumBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleDynamicAlbumBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleAlbumDirPickerRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumDirPicker.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AlbumDirPickerArguments;
        return AlbumDirPicker.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleAlbumDirPickerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleAlbumImporterRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumImporter.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AlbumImporterArguments;
        return AlbumImporter.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleAlbumImporterRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleTrashbinBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == TrashbinBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as TrashbinBrowserArguments;
        return TrashbinBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleTrashbinBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleTrashbinViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == TrashbinViewer.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as TrashbinViewerArguments;
        return TrashbinViewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleTrashbinViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handlePeopleBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == PeopleBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as PeopleBrowserArguments;
        return PeopleBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handlePeopleBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handlePersonBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == PersonBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as PersonBrowserArguments;
        return PersonBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handlePersonBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleSlideshowViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == SlideshowViewer.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as SlideshowViewerArguments;
        return SlideshowViewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleSlideshowViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleSharingBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == SharingBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as SharingBrowserArguments;
        return SharingBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleSharingBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleSharedFileViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == SharedFileViewer.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as SharedFileViewerArguments;
        return SharedFileViewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleSharedFileViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleAlbumShareOutlierBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumShareOutlierBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AlbumShareOutlierBrowserArguments;
        return AlbumShareOutlierBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleAlbumShareOutlierBrowserRoute] Failed while handling route",
          e);
    }
    return null;
  }

  Route<dynamic>? _handleAccountSettingsRoute(RouteSettings settings) {
    try {
      if (settings.name == AccountSettingsWidget.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AccountSettingsWidgetArguments;
        return AccountSettingsWidget.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleAccountSettingsRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleShareFolderPickerRoute(RouteSettings settings) {
    try {
      if (settings.name == ShareFolderPicker.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as ShareFolderPickerArguments;
        return ShareFolderPicker.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleShareFolderPickerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleAlbumPickerRoute(RouteSettings settings) {
    try {
      if (settings.name == AlbumPicker.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as AlbumPickerArguments;
        return AlbumPicker.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleAlbumPickerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleSmartAlbumBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == SmartAlbumBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as SmartAlbumBrowserArguments;
        return SmartAlbumBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleSmartAlbumBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  late AppEventListener<ThemeChangedEvent> _themeChangedListener;
  late AppEventListener<LanguageChangedEvent> _langChangedListener;

  static final _log = Logger("widget.my_app.MyAppState");
}

class _MyScrollBehavior extends MaterialScrollBehavior {
  const _MyScrollBehavior();

  @override
  get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.mouse,
      };
}
