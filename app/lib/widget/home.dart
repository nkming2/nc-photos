import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/or_null.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/import_potential_shared_album.dart';
import 'package:nc_photos/widget/home_albums.dart';
import 'package:nc_photos/widget/home_photos.dart';

class HomeArguments {
  HomeArguments(this.account);

  final Account account;
}

class Home extends StatefulWidget {
  static const routeName = "/home";

  static Route buildRoute(HomeArguments args) => MaterialPageRoute(
        builder: (context) => Home.fromArgs(args),
      );

  const Home({
    Key? key,
    required this.account,
  }) : super(key: key);

  Home.fromArgs(HomeArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _HomeState();

  final Account account;
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  @override
  initState() {
    super.initState();
    if (Pref().isLabEnableSharedAlbumOr(false)) {
      _importPotentialSharedAlbum().then((value) {
        if (value.isNotEmpty) {
          AccountPref.of(widget.account).setNewSharedAlbum(true);
        }
      });
    }
    _animationController.value = 1;
  }

  @override
  dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        bottomNavigationBar: _buildBottomNavigationBar(context),
        body: Builder(builder: (context) => _buildContent(context)),
        extendBody: true,
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      items: <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: const Icon(Icons.photo_outlined),
          label: L10n.global().photosTabLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view_outlined),
          label: L10n.global().collectionsTooltip,
        ),
      ],
      currentIndex: _nextPage,
      onTap: _onTapNavItem,
      backgroundColor: Theme.of(context).bottomAppBarColor.withOpacity(.8),
    );
  }

  Widget _buildContent(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) => SlideTransition(
        position: Tween(
          begin: const Offset(0, .05),
          end: Offset.zero,
        ).animate(_animation),
        child: FadeTransition(
          opacity: _animation,
          child: _buildPage(context, index),
        ),
      ),
    );
  }

  Widget _buildPage(BuildContext context, int index) {
    switch (index) {
      case 0:
        return _buildPhotosPage(context);

      case 1:
        return _buildAlbumsPage(context);

      default:
        throw ArgumentError("Invalid page index: $index");
    }
  }

  Widget _buildPhotosPage(BuildContext context) {
    return HomePhotos(
      account: widget.account,
    );
  }

  Widget _buildAlbumsPage(BuildContext context) {
    return HomeAlbums(
      account: widget.account,
    );
  }

  void _onTapNavItem(int index) {
    _pageController.jumpToPage(index);
    setState(() {
      _nextPage = index;
    });
    _animationController
      ..reset()
      ..forward();
  }

  Future<List<Album>> _importPotentialSharedAlbum() async {
    final c = KiwiContainer().resolve<DiContainer>().copyWith(
          // don't want the potential albums to be cached at this moment
          fileRepo: OrNull(const FileRepo(FileWebdavDataSource())),
          albumRepo: OrNull(AlbumRepo(AlbumRemoteDataSource())),
        );
    try {
      return await ImportPotentialSharedAlbum(c)(
          widget.account, AccountPref.of(widget.account));
    } catch (e, stacktrace) {
      _log.shout(
          "[_importPotentialSharedAlbum] Failed while ImportPotentialSharedAlbum",
          e,
          stacktrace);
      return [];
    }
  }

  final _pageController = PageController(initialPage: 0, keepPage: false);
  int _nextPage = 0;

  late final _animationController = AnimationController(
    duration: k.animationDurationTabTransition,
    vsync: this,
  );
  late final _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeIn,
  );

  static final _log = Logger("widget.home._HomeState");
}
