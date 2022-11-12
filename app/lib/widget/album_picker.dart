import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_album.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album_util.dart' as album_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/album_grid_item.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/new_album_dialog.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';

class AlbumPickerArguments {
  AlbumPickerArguments(this.account);

  final Account account;
}

class AlbumPicker extends StatefulWidget {
  static const routeName = "/album-picker";

  static Route buildRoute(AlbumPickerArguments args) =>
      MaterialPageRoute<Album>(
        builder: (context) => AlbumPicker.fromArgs(args),
      );

  const AlbumPicker({
    Key? key,
    required this.account,
  }) : super(key: key);

  AlbumPicker.fromArgs(AlbumPickerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _AlbumPickerState();

  final Account account;
}

class _AlbumPickerState extends State<AlbumPicker>
    with RouteAware, PageVisibilityMixin {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ListAlbumBloc, ListAlbumBlocState>(
        bloc: _bloc,
        listener: (context, state) => _onStateChange(context, state),
        child: BlocBuilder<ListAlbumBloc, ListAlbumBlocState>(
          bloc: _bloc,
          builder: (context, state) => _buildContent(context, state),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ListAlbumBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
  }

  Widget _buildContent(BuildContext context, ListAlbumBlocState state) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(L10n.global().addToAlbumTooltip),
          floating: true,
        ),
        if (state is ListAlbumBlocLoading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(),
          ),
        SliverPadding(
          padding: const EdgeInsets.all(8),
          sliver: SliverStaggeredGrid.extentBuilder(
            maxCrossAxisExtent: 256,
            mainAxisSpacing: 8,
            staggeredTileBuilder: (_) => const StaggeredTile.count(1, 1),
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildNewAlbumItem(context);
              } else {
                return _buildItem(context, index - 1);
              }
            },
            itemCount: _sortedAlbums.length + 1,
          ),
        ),
      ],
    );
  }

  Widget _buildNewAlbumItem(BuildContext context) {
    return Stack(
      children: [
        AlbumGridItem(
          cover: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              color: Theme.of(context).listPlaceholderBackgroundColor,
              constraints: const BoxConstraints.expand(),
              child: Icon(
                Icons.add,
                color: Theme.of(context).listPlaceholderForegroundColor,
                size: 88,
              ),
            ),
          ),
          title: L10n.global().createAlbumTooltip,
        ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _onNewAlbumPressed(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _sortedAlbums[index];
    return Stack(
      children: [
        AlbumGridItemBuilder(
          account: widget.account,
          album: item,
          isShared: item.shares?.isNotEmpty == true,
        ).build(context),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _onItemPressed(context, item),
            ),
          ),
        ),
      ],
    );
  }

  void _onStateChange(BuildContext context, ListAlbumBlocState state) {
    if (state is ListAlbumBlocInit) {
      _sortedAlbums = [];
    } else if (state is ListAlbumBlocSuccess || state is ListAlbumBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListAlbumBlocFailure) {
      _transformItems(state.items);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else if (state is ListAlbumBlocInconsistent) {
      _reqQuery();
    }
  }

  Future<void> _onNewAlbumPressed(BuildContext context) async {
    try {
      final album = await showDialog<Album>(
        context: context,
        builder: (_) => NewAlbumDialog(
          account: widget.account,
          isAllowDynamic: false,
        ),
      );
      if (album == null) {
        // user canceled
        return;
      }
      Navigator.of(context).pop(album);
    } catch (e, stacktrace) {
      _log.shout("[_onNewAlbumPressed] Failed while showDialog", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onItemPressed(BuildContext context, Album album) {
    Navigator.of(context).pop(album);
  }

  void _transformItems(List<ListAlbumBlocItem> items) {
    _sortedAlbums = album_util.sorted(
        items
            .map((e) => e.album)
            .where((a) => a.provider is AlbumStaticProvider)
            .toList(),
        _getSortFromPref());
  }

  void _reqQuery() {
    _bloc.add(ListAlbumBlocQuery(widget.account));
  }

  late final _bloc = ListAlbumBloc.of(widget.account);
  var _sortedAlbums = <Album>[];

  static final _log = Logger("widget.album_picker._AlbumPickerState");
}

album_util.AlbumSort _getSortFromPref() {
  try {
    return album_util.AlbumSort.values[Pref().getHomeAlbumsSort()!];
  } catch (_) {
    // default
    return album_util.AlbumSort.dateDescending;
  }
}
