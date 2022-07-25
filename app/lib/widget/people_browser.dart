import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_person.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/help_utils.dart' as help_utils;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';
import 'package:nc_photos/widget/person_browser.dart';

class PeopleBrowserArguments {
  PeopleBrowserArguments(this.account);

  final Account account;
}

/// Show a list of all people associated with this account
class PeopleBrowser extends StatefulWidget {
  static const routeName = "/people-browser";

  static Route buildRoute(PeopleBrowserArguments args) => MaterialPageRoute(
        builder: (context) => PeopleBrowser.fromArgs(args),
      );

  const PeopleBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  PeopleBrowser.fromArgs(PeopleBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _PeopleBrowserState();

  final Account account;
}

class _PeopleBrowserState extends State<PeopleBrowser> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListPersonBloc, ListPersonBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListPersonBloc, ListPersonBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ListPersonBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _onStateChange(context, _bloc.state);
        });
      });
    }
    _reqQuery();
  }

  Widget _buildContent(BuildContext context, ListPersonBlocState state) {
    if ((state is ListPersonBlocSuccess || state is ListPersonBlocFailure) &&
        _items.isEmpty) {
      return Column(
        children: [
          AppBar(
            title: Text(L10n.global().collectionPeopleLabel),
            elevation: 0,
            actions: [
              Stack(
                fit: StackFit.passthrough,
                children: [
                  IconButton(
                    onPressed: () {
                      launch(help_utils.peopleUrl);
                    },
                    icon: const Icon(Icons.help_outline),
                    tooltip: L10n.global().helpTooltip,
                  ),
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    end: 0,
                    top: 0,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                      child: Icon(
                        Icons.circle,
                        color: Colors.red,
                        size: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Expanded(
            child: EmptyListIndicator(
              icon: Icons.person_outlined,
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
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.only(top: 8),
                  sliver: SliverStaggeredGrid.extentBuilder(
                    maxCrossAxisExtent: 192,
                    itemCount: _items.length,
                    itemBuilder: _buildItem,
                    staggeredTileBuilder: (index) =>
                        const StaggeredTile.count(1, 1),
                  ),
                ),
              ],
            ),
          ),
          if (state is ListPersonBlocLoading)
            const Align(
              alignment: Alignment.bottomCenter,
              child: LinearProgressIndicator(),
            ),
        ],
      );
    }
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().collectionPeopleLabel),
      floating: true,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return item.buildWidget(context);
  }

  void _onStateChange(BuildContext context, ListPersonBlocState state) {
    if (state is ListPersonBlocInit) {
      _items = [];
    } else if (state is ListPersonBlocSuccess ||
        state is ListPersonBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListPersonBlocFailure) {
      _transformItems(state.items);
      try {
        final e = state.exception as ApiException;
        if (e.response.statusCode == 404) {
          // face recognition app probably not installed, ignore
          return;
        }
      } catch (_) {}
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onItemTap(Person person) {
    Navigator.pushNamed(context, PersonBrowser.routeName,
        arguments: PersonBrowserArguments(widget.account, person));
  }

  void _transformItems(List<Person> items) {
    _items = items
        .sorted((a, b) => a.name.compareTo(b.name))
        .map((e) => _PersonListItem(
              account: widget.account,
              name: e.name,
              faceUrl: api_util.getFacePreviewUrl(widget.account, e.thumbFaceId,
                  size: k.faceThumbSize),
              onTap: () => _onItemTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(ListPersonBlocQuery(widget.account));
  }

  late final _bloc = ListPersonBloc.of(widget.account);

  var _items = <_ListItem>[];

  static final _log = Logger("widget.people_browser._PeopleBrowserState");
}

abstract class _ListItem {
  _ListItem({
    this.onTap,
  });

  Widget buildWidget(BuildContext context);

  final VoidCallback? onTap;
}

class _PersonListItem extends _ListItem {
  _PersonListItem({
    required this.account,
    required this.name,
    required this.faceUrl,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  @override
  buildWidget(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildFaceImage(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: Text(
              name + "\n",
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                    color: AppTheme.getPrimaryTextColor(context),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildFaceImage(BuildContext context) {
    Widget cover;
    try {
      cover = FittedBox(
        clipBehavior: Clip.hardEdge,
        fit: BoxFit.cover,
        child: CachedNetworkImage(
          cacheManager: ThumbnailCacheManager.inst,
          imageUrl: faceUrl!,
          httpHeaders: {
            "Authorization": Api.getAuthorizationHeaderValue(account),
          },
          fadeInDuration: const Duration(),
          filterQuality: FilterQuality.high,
          errorWidget: (context, url, error) {
            // just leave it empty
            return Container();
          },
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        ),
      );
    } catch (_) {
      cover = Icon(
        Icons.person,
        color: Colors.white.withOpacity(.8),
        size: 64,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(128),
      child: Container(
        color: AppTheme.getListItemBackgroundColor(context),
        constraints: const BoxConstraints.expand(),
        child: cover,
      ),
    );
  }

  final Account account;
  final String name;
  final String? faceUrl;
}
