import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_location.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:nc_photos/widget/collection_list_item.dart';
import 'package:nc_photos/widget/place_browser.dart';

class PlacesBrowserArguments {
  const PlacesBrowserArguments(this.account);

  final Account account;
}

/// Show a list of all people associated with this account
class PlacesBrowser extends StatefulWidget {
  static const routeName = "/places-browser";

  static Route buildRoute(PlacesBrowserArguments args) => MaterialPageRoute(
        builder: (context) => PlacesBrowser.fromArgs(args),
      );

  const PlacesBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  PlacesBrowser.fromArgs(PlacesBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _PlacesBrowserState();

  final Account account;
}

class _PlacesBrowserState extends State<PlacesBrowser> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<ListLocationBloc, ListLocationBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListLocationBloc, ListLocationBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ListLocationBlocInit) {
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

  Widget _buildContent(BuildContext context, ListLocationBlocState state) {
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
              if (state is ListLocationBlocLoading)
                const SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.center,
                    child: LinearProgressIndicator(),
                  ),
                ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _countryItems.length,
                    itemBuilder: (context, i) =>
                        _countryItems[i].buildWidget(context),
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 8),
              ),
              SliverStaggeredGrid.extentBuilder(
                maxCrossAxisExtent: 160,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                itemCount: _placeItems.length,
                itemBuilder: (context, i) =>
                    _placeItems[i].buildWidget(context),
                staggeredTileBuilder: (_) => const StaggeredTile.count(1, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().collectionPlacesLabel),
      floating: true,
    );
  }

  void _onStateChange(BuildContext context, ListLocationBlocState state) {
    if (state is ListLocationBlocInit) {
      _placeItems = [];
      _countryItems = [];
    } else if (state is ListLocationBlocSuccess ||
        state is ListLocationBlocLoading) {
      _transformItems(state.result);
    } else if (state is ListLocationBlocFailure) {
      _transformItems(state.result);
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

  void _onPlaceTap(LocationGroup location) {
    Navigator.pushNamed(context, PlaceBrowser.routeName,
        arguments: PlaceBrowserArguments(
            widget.account, location.place, location.countryCode));
  }

  void _onCountryTap(LocationGroup location) {
    Navigator.pushNamed(context, PlaceBrowser.routeName,
        arguments:
            PlaceBrowserArguments(widget.account, null, location.countryCode));
  }

  void _transformItems(LocationGroupResult? result) {
    if (result == null) {
      _placeItems = [];
      _countryItems = [];
      return;
    }

    int sorter(LocationGroup a, LocationGroup b) {
      final compare = b.count.compareTo(a.count);
      if (compare == 0) {
        return a.place.compareTo(b.place);
      } else {
        return compare;
      }
    }

    _placeItems = result.name
        .sorted(sorter)
        .map((e) => _PlaceItem(
              account: widget.account,
              place: e.place,
              thumbUrl: api_util.getFilePreviewUrlByFileId(
                widget.account,
                e.latestFileId,
                width: k.photoThumbSize,
                height: k.photoThumbSize,
              ),
              onTap: () => _onPlaceTap(e),
            ))
        .toList();
    _countryItems = result.countryCode
        .sorted(sorter)
        .map((e) => _CountryItem(
              account: widget.account,
              country: e.place,
              thumbUrl: api_util.getFilePreviewUrlByFileId(
                widget.account,
                e.latestFileId,
                width: k.photoThumbSize,
                height: k.photoThumbSize,
              ),
              onTap: () => _onCountryTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(ListLocationBlocQuery(widget.account));
  }

  late final _bloc = ListLocationBloc(KiwiContainer().resolve<DiContainer>());

  var _placeItems = <_PlaceItem>[];
  var _countryItems = <_CountryItem>[];

  static final _log = Logger("widget.places_browser._PlacesBrowserState");
}

class _PlaceItem {
  const _PlaceItem({
    required this.account,
    required this.place,
    required this.thumbUrl,
    this.onTap,
  });

  Widget buildWidget(BuildContext context) => CollectionListSmall(
        account: account,
        label: place,
        coverUrl: thumbUrl,
        fallbackBuilder: (_) => Icon(
          Icons.location_on,
          color: Colors.white.withOpacity(.8),
        ),
        onTap: onTap,
      );

  final Account account;
  final String place;
  final String thumbUrl;
  final VoidCallback? onTap;
}

class _CountryItem {
  const _CountryItem({
    required this.account,
    required this.country,
    required this.thumbUrl,
    this.onTap,
  });

  Widget buildWidget(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CachedNetworkImage(
                cacheManager: ThumbnailCacheManager.inst,
                imageUrl: thumbUrl,
                httpHeaders: {
                  "Authorization": Api.getAuthorizationHeaderValue(account),
                },
                fadeInDuration: const Duration(),
                filterQuality: FilterQuality.high,
                errorWidget: (_, __, ___) => Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 8, 0, 8),
                  child: Icon(
                    Icons.location_on,
                    color: AppTheme.getUnfocusedIconColor(context),
                  ),
                ),
                imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
              ),
              const SizedBox(width: 8),
              Text(country),
              const SizedBox(width: 8),
            ],
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.getListItemBackgroundColor(context),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          if (onTap != null)
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: onTap,
                ),
              ),
            ),
        ],
      ),
    );
  }

  final Account account;
  final String country;
  final String thumbUrl;
  final VoidCallback? onTap;
}
