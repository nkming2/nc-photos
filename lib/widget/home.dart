import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/home_albums.dart';
import 'package:nc_photos/widget/home_photos.dart';

class HomeArguments {
  HomeArguments(this.account);

  final Account account;
}

class Home extends StatefulWidget {
  static const routeName = "/home";

  Home({
    Key key,
    @required this.account,
  }) : super(key: key);

  Home.fromArgs(HomeArguments args, {Key key})
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
    _pageController = PageController(initialPage: 0, keepPage: false);
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
          label: AppLocalizations.of(context).photosTabLabel,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.photo_album_outlined),
          label: AppLocalizations.of(context).albumsTabLabel,
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

  PageController _pageController;
  int _nextPage = 0;
}
