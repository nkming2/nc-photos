import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/language_util.dart' as language_util;
import 'package:nc_photos/navigation_manager.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_browser.dart';
import 'package:nc_photos/widget/album_dir_picker.dart';
import 'package:nc_photos/widget/album_importer.dart';
import 'package:nc_photos/widget/album_picker.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';
import 'package:nc_photos/widget/archive_browser.dart';
import 'package:nc_photos/widget/changelog.dart';
import 'package:nc_photos/widget/connect.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';
import 'package:nc_photos/widget/enhanced_photo_browser.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/image_editor.dart';
import 'package:nc_photos/widget/local_file_viewer.dart';
import 'package:nc_photos/widget/people_browser.dart';
import 'package:nc_photos/widget/person_browser.dart';
import 'package:nc_photos/widget/place_browser.dart';
import 'package:nc_photos/widget/places_browser.dart';
import 'package:nc_photos/widget/result_viewer.dart';
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
import 'package:nc_photos/widget/tag_browser.dart';
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

class _MyAppState extends State<MyApp>
    implements SnackBarHandler, NavigationHandler {
  @override
  void initState() {
    super.initState();
    SnackBarManager().registerHandler(this);
    NavigationManager().setHandler(this);
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
      theme: AppTheme.buildLightThemeData(),
      darkTheme: AppTheme.buildDarkThemeData(),
      themeMode: themeMode,
      initialRoute: Splash.routeName,
      onGenerateRoute: _onGenerateRoute,
      navigatorObservers: <NavigatorObserver>[MyApp.routeObserver],
      navigatorKey: _navigatorKey,
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
        Locale("pt"),
        Locale.fromSubtags(languageCode: "zh", scriptCode: "Hans"),
        Locale.fromSubtags(languageCode: "zh", scriptCode: "Hant"),
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
    NavigationManager().unsetHandler(this);
    _themeChangedListener.end();
    _langChangedListener.end();
  }

  @override
  showSnackBar(SnackBar snackBar) =>
      _scaffoldMessengerKey.currentState?.showSnackBar(snackBar);

  @override
  getNavigator() => _navigatorKey.currentState;

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
    route ??= _handlePersonBrowserRoute(settings);
    route ??= _handleSlideshowViewerRoute(settings);
    route ??= _handleSharingBrowserRoute(settings);
    route ??= _handleSharedFileViewerRoute(settings);
    route ??= _handleAlbumShareOutlierBrowserRoute(settings);
    route ??= _handleAccountSettingsRoute(settings);
    route ??= _handleShareFolderPickerRoute(settings);
    route ??= _handleAlbumPickerRoute(settings);
    route ??= _handleSmartAlbumBrowserRoute(settings);
    route ??= _handleEnhancedPhotoBrowserRoute(settings);
    route ??= _handleLocalFileViewerRoute(settings);
    route ??= _handleEnhancementSettingsRoute(settings);
    route ??= _handleImageEditorRoute(settings);
    route ??= _handleChangelogRoute(settings);
    route ??= _handleTagBrowserRoute(settings);
    route ??= _handlePeopleBrowserRoute(settings);
    route ??= _handlePlaceBrowserRoute(settings);
    route ??= _handlePlacesBrowserRoute(settings);
    route ??= _handleResultViewerRoute(settings);
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

  Route<dynamic>? _handleEnhancedPhotoBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == EnhancedPhotoBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as EnhancedPhotoBrowserArguments;
        return EnhancedPhotoBrowser.buildRoute(args);
      } else if (settings.name
              ?.startsWith("${EnhancedPhotoBrowser.routeName}?") ==
          true) {
        final queries = Uri.parse(settings.name!).queryParameters;
        final args = EnhancedPhotoBrowserArguments(queries["filename"]);
        return EnhancedPhotoBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleEnhancedPhotoBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleLocalFileViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == LocalFileViewer.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as LocalFileViewerArguments;
        return LocalFileViewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe(
          "[_handleLocalFileViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleEnhancementSettingsRoute(RouteSettings settings) {
    try {
      if (settings.name == EnhancementSettings.routeName) {
        return EnhancementSettings.buildRoute();
      }
    } catch (e) {
      _log.severe(
          "[_handleEnhancementSettingsRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleImageEditorRoute(RouteSettings settings) {
    try {
      if (settings.name == ImageEditor.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as ImageEditorArguments;
        return ImageEditor.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleImageEditorRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleChangelogRoute(RouteSettings settings) {
    try {
      if (settings.name == Changelog.routeName) {
        if (settings.arguments != null) {
          final args = settings.arguments as ChangelogArguments;
          return Changelog.buildRoute(args);
        } else {
          return MaterialPageRoute(builder: (_) => const Changelog());
        }
      }
    } catch (e) {
      _log.severe("[_handleChangelogRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleTagBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == TagBrowser.routeName && settings.arguments != null) {
        final args = settings.arguments as TagBrowserArguments;
        return TagBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleTagBrowserRoute] Failed while handling route", e);
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

  Route<dynamic>? _handlePlaceBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == PlaceBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as PlaceBrowserArguments;
        return PlaceBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handlePlaceBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handlePlacesBrowserRoute(RouteSettings settings) {
    try {
      if (settings.name == PlacesBrowser.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as PlacesBrowserArguments;
        return PlacesBrowser.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handlePlacesBrowserRoute] Failed while handling route", e);
    }
    return null;
  }

  Route<dynamic>? _handleResultViewerRoute(RouteSettings settings) {
    try {
      if (settings.name == ResultViewer.routeName &&
          settings.arguments != null) {
        final args = settings.arguments as ResultViewerArguments;
        return ResultViewer.buildRoute(args);
      } else if (settings.name?.startsWith("${ResultViewer.routeName}?") ==
          true) {
        final queries = Uri.parse(settings.name!).queryParameters;
        final fileUrl = Uri.decodeQueryComponent(queries["url"]!);
        final args = ResultViewerArguments(fileUrl);
        return ResultViewer.buildRoute(args);
      }
    } catch (e) {
      _log.severe("[_handleResultViewerRoute] Failed while handling route", e);
    }
    return null;
  }

  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final _navigatorKey = GlobalKey<NavigatorState>();

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
