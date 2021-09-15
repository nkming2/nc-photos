import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_pending_shared_album.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/import_potential_shared_album.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:tuple/tuple.dart';

class PendingAlbumsArguments {
  PendingAlbumsArguments(this.account);

  final Account account;
}

class PendingAlbums extends StatefulWidget {
  static const routeName = "/pending-albums";

  static Route buildRoute(PendingAlbumsArguments args) => MaterialPageRoute(
        builder: (context) => PendingAlbums.fromArgs(args),
      );

  const PendingAlbums({
    Key? key,
    required this.account,
  }) : super(key: key);

  PendingAlbums.fromArgs(PendingAlbumsArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _PendingAlbumsState();

  final Account account;
}

class _PendingAlbumsState extends State<PendingAlbums> {
  @override
  initState() {
    super.initState();
    _importPotentialSharedAlbum().then((_) {
      _bloc.add(ListPendingSharedAlbumBlocQuery(widget.account));
    });
    Pref.inst().setNewSharedAlbum(false);
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListPendingSharedAlbumBloc,
            ListPendingSharedAlbumBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListPendingSharedAlbumBloc,
              ListPendingSharedAlbumBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ListPendingSharedAlbumBlocState state) {
    if (state is ListPendingSharedAlbumBlocSuccess && _items.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: const Text("Sharing with you"),
            elevation: 0,
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.share_outlined,
              text: L10n.global().listEmptyText,
            ),
          ),
        ],
      );
    } else {
      return Stack(
        children: [
          Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    secondary: AppTheme.getOverscrollIndicatorColor(context),
                  ),
            ),
            child: CustomScrollView(
              slivers: [
                const SliverAppBar(
                  title: Text("Sharing with you"),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(8),
                  sliver: SliverStaggeredGrid.extentBuilder(
                    maxCrossAxisExtent: 256,
                    mainAxisSpacing: 8,
                    itemCount: _items.length,
                    itemBuilder: _buildItem,
                    staggeredTileBuilder: (_) =>
                        const StaggeredTile.count(1, 1),
                  ),
                ),
              ],
            ),
          ),
          if (!_isReady || state is ListPendingSharedAlbumBlocLoading)
            const Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(),
            ),
        ],
      );
    }
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return Stack(
      children: [
        AlbumGridItemBuilder(
          account: widget.account,
          album: item.album,
        ).build(context),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _onItemTap(context, item),
            ),
          ),
        ),
      ],
    );
  }

  void _onStateChange(
      BuildContext context, ListPendingSharedAlbumBlocState state) {
    if (state is ListPendingSharedAlbumBlocSuccess ||
        state is ListPendingSharedAlbumBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListPendingSharedAlbumBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ListPendingSharedAlbumBlocInconsistent) {
      _bloc.add(ListPendingSharedAlbumBlocQuery(widget.account));
    }
    _isReady = true;
  }

  void _onItemTap(BuildContext context, _GridItem item) {
    album_browser_util.open(context, widget.account, item.album);
  }

  void _transformItems(List<ListPendingSharedAlbumBlocItem> items) {
    final sortedAlbums = items
        .map((e) => Tuple2(
            e.album.provider.latestItemTime ?? e.album.lastUpdated, e.album))
        .sorted((a, b) {
      // then sort in descending order
      final tmp = b.item1.compareTo(a.item1);
      if (tmp != 0) {
        return tmp;
      } else {
        return a.item2.name.compareTo(b.item2.name);
      }
    }).map((e) => e.item2);
    _items.clear();
    _items.addAll(sortedAlbums.map((e) => _GridItem(e)));
  }

  Future<void> _importPotentialSharedAlbum() async {
    const fileRepo = FileRepo(FileWebdavDataSource());
    // don't want the potential albums to be cached at this moment
    final albumRepo = AlbumRepo(AlbumRemoteDataSource());
    try {
      await ImportPotentialSharedAlbum(fileRepo, albumRepo)(widget.account);
    } catch (e, stacktrace) {
      _log.shout(
          "[_importPotentialSharedAlbum] Failed while ImportPotentialSharedAlbum",
          e,
          stacktrace);
    }
  }

  final _bloc = ListPendingSharedAlbumBloc();
  bool _isReady = false;

  final _items = <_GridItem>[];

  static final _log = Logger("widget.pending_albums._PendingAlbumsState");
}

class _GridItem {
  _GridItem(this.album);

  Album album;
}
