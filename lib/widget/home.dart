import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/lab.dart';
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

  Home({
    Key? key,
    required this.account,
  }) : super(key: key);

  Home.fromArgs(HomeArguments args, {Key? key})
      : this(
          account: args.account,
        );

  @override
  createState() => _HomeState();

  final Account account;
}

class _HomeState extends State<Home> {
  @override
  initState() {
    super.initState();
    if (Lab().enableSharedAlbum) {
      _importPotentialSharedAlbum().then((value) {
        if (value.isNotEmpty) {
          Pref.inst().setNewSharedAlbum(true);
        }
      });
    }
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        bottomNavigationBar: _buildBottomNavigationBar(context),
        body: Builder(builder: (context) => _buildContent(context)),
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
    );
  }

  Widget _buildContent(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: _buildPage,
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
    _pageController.animateToPage(index,
        duration: k.animationDurationNormal, curve: Curves.easeInOut);
    setState(() {
      _nextPage = index;
    });
  }

  Future<List<Album>> _importPotentialSharedAlbum() async {
    final fileRepo = FileRepo(FileWebdavDataSource());
    // don't want the potential albums to be cached at this moment
    final albumRepo = AlbumRepo(AlbumRemoteDataSource());
    try {
      return await ImportPotentialSharedAlbum(fileRepo, albumRepo)(
          widget.account);
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

  static final _log = Logger("widget.home._HomeState");
}
