import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/search_landing.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/person_browser.dart';

class SearchLanding extends StatefulWidget {
  const SearchLanding({
    Key? key,
    required this.account,
    this.onFavoritePressed,
    this.onVideoPressed,
  }) : super(key: key);

  @override
  createState() => _SearchLandingState();

  final Account account;
  final VoidCallback? onFavoritePressed;
  final VoidCallback? onVideoPressed;
}

class _SearchLandingState extends State<SearchLanding> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return BlocListener<SearchLandingBloc, SearchLandingBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child: BlocBuilder<SearchLandingBloc, SearchLandingBlocState>(
        bloc: _bloc,
        builder: (context, state) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  secondary: AppTheme.getOverscrollIndicatorColor(context),
                ),
          ),
          child: _buildContent(context, state),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is SearchLandingBlocInit) {
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

  Widget _buildContent(BuildContext context, SearchLandingBlocState state) {
    return Column(
      children: [
        if (AccountPref.of(widget.account).isEnableFaceRecognitionAppOr())
          ..._buildPeopleSection(context, state),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(L10n.global().categoriesLabel),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.star_border),
          title: Text(L10n.global().collectionFavoritesLabel),
          onTap: _onFavoritePressed,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1),
        ),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.ondemand_video_outlined),
          title: Text(L10n.global().searchLandingCategoryVideosLabel),
          onTap: _onVideoPressed,
        ),
      ],
    );
  }

  List<Widget> _buildPeopleSection(
      BuildContext context, SearchLandingBlocState state) {
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(L10n.global().collectionPeopleLabel),
        trailing: IconButton(
          onPressed: () {
            launch(help_util.peopleUrl);
          },
          tooltip: L10n.global().helpTooltip,
          icon: const Icon(Icons.help_outline),
        ),
      ),
      if ((state is SearchLandingBlocSuccess ||
              state is SearchLandingBlocFailure) &&
          state.persons.isEmpty)
        SizedBox(
          height: 48,
          child: Center(
            child: Text(L10n.global().searchLandingPeopleListEmptyText),
          ),
        )
      else
        SizedBox(
          height: 128,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: state.persons.length,
            itemBuilder: (context, i) => _buildItem(context, i),
          ),
        ),
    ];
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return item.buildWidget(context);
  }

  void _onStateChange(BuildContext context, SearchLandingBlocState state) {
    if (state is SearchLandingBlocInit) {
      _items = [];
    } else if (state is SearchLandingBlocSuccess ||
        state is SearchLandingBlocLoading) {
      _transformItems(state.persons);
    } else if (state is SearchLandingBlocFailure) {
      _transformItems(state.persons);
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

  void _onFavoritePressed() {
    widget.onFavoritePressed?.call();
  }

  void _onVideoPressed() {
    widget.onVideoPressed?.call();
  }

  void _onItemTap(Person person) {
    Navigator.pushNamed(context, PersonBrowser.routeName,
        arguments: PersonBrowserArguments(widget.account, person));
  }

  void _transformItems(List<Person> items) {
    _items = items
        .sorted((a, b) => a.name.compareTo(b.name))
        .map((e) => _LandingPersonItem(
              account: widget.account,
              name: e.name,
              faceUrl: api_util.getFacePreviewUrl(widget.account, e.thumbFaceId,
                  size: k.faceThumbSize),
              onTap: () => _onItemTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(SearchLandingBlocQuery(widget.account));
  }

  late final _bloc = SearchLandingBloc(KiwiContainer().resolve<DiContainer>());

  var _items = <_LandingPersonItem>[];

  static final _log = Logger("widget.search_landing._SearchLandingState");
}

class _LandingPersonItem {
  _LandingPersonItem({
    required this.account,
    required this.name,
    required this.faceUrl,
    this.onTap,
  });

  buildWidget(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          SizedBox(
            width: 88,
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
    Widget buildPlaceholder() => Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.person,
            color: Colors.white.withOpacity(.8),
          ),
        );
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
          errorWidget: (context, url, error) => buildPlaceholder(),
          imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
        ),
      );
    } catch (_) {
      cover = FittedBox(
        child: buildPlaceholder(),
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
  final VoidCallback? onTap;
}
