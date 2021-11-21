import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_sharing.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/import_potential_shared_album.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/shared_file_viewer.dart';
import 'package:nc_photos/widget/unbounded_list_tile.dart';

class SharingBrowserArguments {
  SharingBrowserArguments(this.account);

  final Account account;
}

/// Show a list of all shares associated with this account
class SharingBrowser extends StatefulWidget {
  static const routeName = "/sharing-browser";

  static Route buildRoute(SharingBrowserArguments args) => MaterialPageRoute(
        builder: (context) => SharingBrowser.fromArgs(args),
      );

  const SharingBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  SharingBrowser.fromArgs(SharingBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _SharingBrowserState();

  final Account account;
}

class _SharingBrowserState extends State<SharingBrowser> {
  @override
  initState() {
    super.initState();
    if (Pref().isLabEnableSharedAlbumOr(false)) {
      _importPotentialSharedAlbum().whenComplete(() {
        _initBloc();
      });
      Pref().setNewSharedAlbum(false);
    } else {
      _initBloc();
    }
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListSharingBloc, ListSharingBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListSharingBloc, ListSharingBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ListSharingBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
    } else {
      // process the current state
      WidgetsBinding.instance!.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
    _reqQuery();
  }

  Widget _buildContent(BuildContext context, ListSharingBlocState state) {
    if ((state is ListSharingBlocSuccess || state is ListSharingBlocFailure) &&
        state.items.isEmpty) {
      return _buildEmptyContent(context);
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
                SliverAppBar(
                  title: Text(L10n.global().collectionSharingLabel),
                  floating: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildItem(context, _items[index]),
                    childCount: _items.length,
                  ),
                ),
              ],
            ),
          ),
          if (state is ListSharingBlocLoading)
            const Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(),
            ),
        ],
      );
    }
  }

  Widget _buildEmptyContent(BuildContext context) {
    return Column(
      children: [
        AppBar(
          title: Text(L10n.global().collectionSharingLabel),
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
  }

  Widget _buildFileItem(BuildContext context, List<ListSharingItem> shares) {
    assert(shares.first is ListSharingFile);
    final dateStr =
        _getDateFormat(context).format(shares.first.share.stime.toLocal());
    final firstItem = shares.first as ListSharingFile;
    return _ListTile(
      leading: shares.first.share.itemType == ShareItemType.folder
          ? SizedBox(
              height: _leadingSize,
              width: _leadingSize,
              child: Icon(
                Icons.folder,
                size: 32,
                color: AppTheme.getUnfocusedIconColor(context),
              ),
            )
          : CachedNetworkImage(
              width: _leadingSize,
              height: _leadingSize,
              cacheManager: ThumbnailCacheManager.inst,
              imageUrl: api_util.getFilePreviewUrl(
                  widget.account, firstItem.file,
                  width: k.photoThumbSize, height: k.photoThumbSize),
              httpHeaders: {
                "Authorization":
                    Api.getAuthorizationHeaderValue(widget.account),
              },
              fadeInDuration: const Duration(),
              filterQuality: FilterQuality.high,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
              errorWidget: (context, url, error) => Icon(
                Icons.image_not_supported,
                size: 32,
                color: AppTheme.getUnfocusedIconColor(context),
              ),
            ),
      label: shares.first.share.filename,
      description: shares.first.share.uidOwner == widget.account.username
          ? L10n.global().fileLastSharedDescription(dateStr)
          : L10n.global().fileLastSharedByOthersDescription(
              shares.first.share.displaynameOwner, dateStr),
      trailing: (shares.any((element) => element.share.url?.isNotEmpty == true))
          ? Icon(
              Icons.link,
              color: AppTheme.getUnfocusedIconColor(context),
            )
          : null,
      onTap: () {
        Navigator.of(context).pushNamed(SharedFileViewer.routeName,
            arguments: SharedFileViewerArguments(
              widget.account,
              firstItem.file,
              shares.map((e) => e.share).toList(),
            ));
      },
    );
  }

  Widget _buildAlbumItem(BuildContext context, List<ListSharingItem> shares) {
    assert(shares.first is ListSharingAlbum);
    final dateStr =
        _getDateFormat(context).format(shares.first.share.stime.toLocal());
    final firstItem = shares.first as ListSharingAlbum;
    final cover = firstItem.album.coverProvider.getCover(firstItem.album);
    return _ListTile(
      leading: cover == null
          ? SizedBox(
              height: _leadingSize,
              width: _leadingSize,
              child: Icon(
                Icons.photo_album_outlined,
                size: 32,
                color: AppTheme.getUnfocusedIconColor(context),
              ),
            )
          : CachedNetworkImage(
              width: _leadingSize,
              height: _leadingSize,
              cacheManager: ThumbnailCacheManager.inst,
              imageUrl: api_util.getFilePreviewUrl(widget.account, cover,
                  width: k.photoThumbSize, height: k.photoThumbSize),
              httpHeaders: {
                "Authorization":
                    Api.getAuthorizationHeaderValue(widget.account),
              },
              fadeInDuration: const Duration(),
              filterQuality: FilterQuality.high,
              imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
              errorWidget: (context, url, error) => Icon(
                Icons.panorama,
                size: 32,
                color: AppTheme.getUnfocusedIconColor(context),
              ),
            ),
      label: firstItem.album.name,
      description: shares.first.share.uidOwner == widget.account.username
          ? L10n.global().fileLastSharedDescription(dateStr)
          : L10n.global().albumLastSharedByOthersDescription(
              shares.first.share.displaynameOwner, dateStr),
      trailing: Icon(
        Icons.photo_album_outlined,
        color: AppTheme.getUnfocusedIconColor(context),
      ),
      onTap: () =>
          _onAlbumShareItemTap(context, shares.first as ListSharingAlbum),
    );
  }

  Widget _buildItem(BuildContext context, List<ListSharingItem> shares) {
    if (shares.first is ListSharingFile) {
      return _buildFileItem(context, shares);
    } else if (shares.first is ListSharingAlbum) {
      return _buildAlbumItem(context, shares);
    } else {
      throw StateError("Unknown item type: ${shares.first.runtimeType}");
    }
  }

  void _onStateChange(BuildContext context, ListSharingBlocState state) {
    if (state is ListSharingBlocInit) {
      _items = [];
    } else if (state is ListSharingBlocSuccess ||
        state is ListSharingBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListSharingBlocFailure) {
      _transformItems(state.items);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<void> _onAlbumShareItemTap(
      BuildContext context, ListSharingAlbum share) {
    return album_browser_util.push(context, widget.account, share.album);
  }

  void _transformItems(List<ListSharingItem> items) {
    // group shares of the same file
    final map = <String, List<ListSharingItem>>{};
    for (final i in items) {
      final isSharedByMe = (i.share.uidOwner == widget.account.username);
      final groupKey = "${i.share.path}?$isSharedByMe";
      map[groupKey] ??= <ListSharingItem>[];
      map[groupKey]!.add(i);
    }
    // sort the sub-lists
    for (final list in map.values) {
      list.sort((a, b) => b.share.stime.compareTo(a.share.stime));
    }
    // then sort the map and convert it to list
    _items = map.entries
        .sorted((a, b) =>
            b.value.first.share.stime.compareTo(a.value.first.share.stime))
        .map((e) => e.value)
        .toList();
  }

  void _reqQuery() {
    _bloc.add(ListSharingBlocQuery(widget.account));
  }

  Future<List<Album>> _importPotentialSharedAlbum() async {
    const fileRepo = FileRepo(FileWebdavDataSource());
    // don't want the potential albums to be cached at this moment
    final albumRepo = AlbumRepo(AlbumRemoteDataSource());
    try {
      return await ImportPotentialSharedAlbum(fileRepo, albumRepo)(
          widget.account, Pref().getAccountSettings(widget.account));
    } catch (e, stackTrace) {
      _log.shout(
          "[_importPotentialSharedAlbum] Failed while ImportPotentialSharedAlbum",
          e,
          stackTrace);
      return [];
    }
  }

  late final _bloc = ListSharingBloc.of(widget.account);

  var _items = <List<ListSharingItem>>[];

  static final _log = Logger("widget.sharing_browser._SharingBrowserState");
}

class _ListTile extends StatelessWidget {
  const _ListTile({
    required this.leading,
    required this.label,
    required this.description,
    this.trailing,
    required this.onTap,
  });

  @override
  build(BuildContext context) {
    return UnboundedListTile(
      leading: leading,
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(description),
      trailing: trailing,
      onTap: onTap,
    );
  }

  final Widget leading;
  final String label;
  final String description;
  final Widget? trailing;
  final VoidCallback onTap;
}

const _leadingSize = 56.0;

DateFormat _getDateFormat(BuildContext context) => DateFormat(
    DateFormat.YEAR_ABBR_MONTH_DAY,
    Localizations.localeOf(context).languageCode);
