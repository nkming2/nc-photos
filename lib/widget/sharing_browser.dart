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
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/shared_file_viewer.dart';

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
    _initBloc();
    _shareRemovedListener.begin();
  }

  @override
  dispose() {
    _shareRemovedListener.end();
    super.dispose();
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
      return CustomScrollView(
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

  Widget _buildItem(BuildContext context, List<ListSharingItem> shares) {
    const leadingSize = 56.0;
    final dateStr = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY,
            Localizations.localeOf(context).languageCode)
        .format(shares.first.share.stime.toLocal());
    return InkWell(
      onTap: () {
        Navigator.of(context).pushNamed(SharedFileViewer.routeName,
            arguments: SharedFileViewerArguments(
              widget.account,
              shares.first.file,
              shares.map((e) => e.share).toList(),
            ));
      },
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            shares.first.share.itemType == ShareItemType.folder
                ? const Icon(
                    Icons.folder_outlined,
                    size: leadingSize,
                  )
                : CachedNetworkImage(
                    width: leadingSize,
                    height: leadingSize,
                    cacheManager: ThumbnailCacheManager.inst,
                    imageUrl: api_util.getFilePreviewUrl(
                        widget.account, shares.first.file,
                        width: k.photoThumbSize, height: k.photoThumbSize),
                    httpHeaders: {
                      "Authorization":
                          Api.getAuthorizationHeaderValue(widget.account),
                    },
                    fadeInDuration: const Duration(),
                    filterQuality: FilterQuality.high,
                    imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                  ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shares.first.share.filename,
                    style: Theme.of(context).textTheme.subtitle1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    L10n.global().fileLastSharedDescription(dateStr),
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            if (shares.any((element) => element.share.url?.isNotEmpty == true))
              const Icon(Icons.link)
          ],
        ),
      ),
    );
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

  void _onShareRemovedEvent(ShareRemovedEvent ev) {}

  void _transformItems(List<ListSharingItem> items) {
    // group shares of the same file
    final map = <String, List<ListSharingItem>>{};
    for (final i in items) {
      map[i.share.path] ??= <ListSharingItem>[];
      map[i.share.path]!.add(i);
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

  late final _bloc = ListSharingBloc.of(widget.account);
  late final _shareRemovedListener =
      AppEventListener<ShareRemovedEvent>(_onShareRemovedEvent);

  var _items = <List<ListSharingItem>>[];

  static final _log = Logger("widget.sharing_browser._SharingBrowserState");
}
