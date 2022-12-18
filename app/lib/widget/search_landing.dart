import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/search_landing.dart';
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
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:nc_photos/widget/people_browser.dart';
import 'package:nc_photos/widget/person_browser.dart';
import 'package:nc_photos/widget/place_browser.dart';
import 'package:nc_photos/widget/places_browser.dart';
import 'package:np_codegen/np_codegen.dart';

part 'search_landing.g.dart';

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

@npLog
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
        builder: (context, state) => _buildContent(context, state),
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
        if (mounted) {
          setState(() {
            _onStateChange(context, _bloc.state);
          });
        }
      });
    }
  }

  Widget _buildContent(BuildContext context, SearchLandingBlocState state) {
    return Column(
      children: [
        if (AccountPref.of(widget.account).isEnableFaceRecognitionAppOr())
          ..._buildPeopleSection(context, state),
        ..._buildLocationSection(context, state),
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
    final isNoResult = (state is SearchLandingBlocSuccess ||
            state is SearchLandingBlocFailure) &&
        _personItems.isEmpty;
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(L10n.global().collectionPeopleLabel),
        trailing: isNoResult
            ? IconButton(
                onPressed: () {
                  launch(help_util.peopleUrl);
                },
                tooltip: L10n.global().helpTooltip,
                icon: const Icon(Icons.help_outline),
              )
            : TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(PeopleBrowser.routeName,
                      arguments: PeopleBrowserArguments(widget.account));
                },
                child: Text(L10n.global().showAllButtonLabel),
              ),
      ),
      if (isNoResult)
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
            itemCount: _personItems.length,
            itemBuilder: (context, i) => _personItems[i].buildWidget(context),
          ),
        ),
    ];
  }

  List<Widget> _buildLocationSection(
      BuildContext context, SearchLandingBlocState state) {
    final isNoResult = (state is SearchLandingBlocSuccess ||
            state is SearchLandingBlocFailure) &&
        _locationItems.isEmpty;
    return [
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(L10n.global().collectionPlacesLabel),
        trailing: isNoResult
            ? null
            : TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(PlacesBrowser.routeName,
                      arguments: PlacesBrowserArguments(widget.account));
                },
                child: Text(L10n.global().showAllButtonLabel),
              ),
      ),
      if (isNoResult)
        SizedBox(
          height: 48,
          child: Center(
            child: Text(L10n.global().listNoResultsText),
          ),
        )
      else
        SizedBox(
          height: 128,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _locationItems.length,
            itemBuilder: (context, i) => _locationItems[i].buildWidget(context),
          ),
        ),
    ];
  }

  void _onStateChange(BuildContext context, SearchLandingBlocState state) {
    if (state is SearchLandingBlocInit) {
      _personItems = [];
      _locationItems = [];
    } else if (state is SearchLandingBlocSuccess ||
        state is SearchLandingBlocLoading) {
      _transformItems(state.persons, state.locations);
    } else if (state is SearchLandingBlocFailure) {
      _transformItems(state.persons, state.locations);
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

  void _onPersonItemTap(Person person) {
    Navigator.pushNamed(context, PersonBrowser.routeName,
        arguments: PersonBrowserArguments(widget.account, person));
  }

  void _onLocationItemTap(LocationGroup location) {
    Navigator.of(context).pushNamed(
      PlaceBrowser.routeName,
      arguments: PlaceBrowserArguments(
          widget.account, location.place, location.countryCode),
    );
  }

  void _transformItems(List<Person> persons, LocationGroupResult locations) {
    _transformPersons(persons);
    _transformLocations(locations);
  }

  void _transformPersons(List<Person> persons) {
    _personItems = persons
        .sorted((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare == 0) {
            return a.name.compareTo(b.name);
          } else {
            return countCompare;
          }
        })
        .take(10)
        .map((e) => _LandingPersonItem(
              account: widget.account,
              name: e.name,
              faceUrl: api_util.getFacePreviewUrl(widget.account, e.thumbFaceId,
                  size: k.faceThumbSize),
              onTap: () => _onPersonItemTap(e),
            ))
        .toList();
  }

  void _transformLocations(LocationGroupResult locations) {
    _locationItems = locations.name
        .sorted((a, b) {
          final compare = b.count.compareTo(a.count);
          if (compare == 0) {
            return a.place.compareTo(b.place);
          } else {
            return compare;
          }
        })
        .take(10)
        .map((e) => _LandingLocationItem(
              account: widget.account,
              name: e.place,
              thumbUrl: api_util.getFilePreviewUrlByFileId(
                widget.account,
                e.latestFileId,
                width: k.photoThumbSize,
                height: k.photoThumbSize,
              ),
              onTap: () => _onLocationItemTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(SearchLandingBlocQuery(widget.account));
  }

  late final _bloc = SearchLandingBloc(KiwiContainer().resolve<DiContainer>());

  var _personItems = <_LandingPersonItem>[];
  var _locationItems = <_LandingLocationItem>[];
}

class _LandingPersonItem {
  _LandingPersonItem({
    required this.account,
    required this.name,
    required this.faceUrl,
    this.onTap,
  });

  Widget buildWidget(BuildContext context) => _LandingItemWidget(
        account: account,
        label: name,
        coverUrl: faceUrl,
        onTap: onTap,
        fallbackBuilder: (_) => Icon(
          Icons.person,
          color: Theme.of(context).listPlaceholderForegroundColor,
        ),
      );

  final Account account;
  final String name;
  final String faceUrl;
  final VoidCallback? onTap;
}

class _LandingLocationItem {
  const _LandingLocationItem({
    required this.account,
    required this.name,
    required this.thumbUrl,
    this.onTap,
  });

  Widget buildWidget(BuildContext context) => _LandingItemWidget(
        account: account,
        label: name,
        coverUrl: thumbUrl,
        onTap: onTap,
        fallbackBuilder: (_) => Icon(
          Icons.location_on,
          color: Theme.of(context).listPlaceholderForegroundColor,
        ),
      );

  final Account account;
  final String name;
  final String thumbUrl;
  final VoidCallback? onTap;
}

class _LandingItemWidget extends StatelessWidget {
  const _LandingItemWidget({
    Key? key,
    required this.account,
    required this.label,
    required this.coverUrl,
    required this.fallbackBuilder,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: _buildCoverImage(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 88,
            child: Text(
              label + "\n",
              style: Theme.of(context).textTheme.bodyMedium,
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

  Widget _buildCoverImage(BuildContext context) {
    Widget cover;
    Widget buildPlaceholder() => Padding(
          padding: const EdgeInsets.all(8),
          child: fallbackBuilder(context),
        );
    try {
      cover = NetworkRectThumbnail(
        account: account,
        imageUrl: coverUrl,
        errorBuilder: (_) => buildPlaceholder(),
      );
    } catch (_) {
      cover = FittedBox(
        child: buildPlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(128),
      child: Container(
        color: Theme.of(context).listPlaceholderBackgroundColor,
        constraints: const BoxConstraints.expand(),
        child: cover,
      ),
    );
  }

  final Account account;
  final String label;
  final String coverUrl;
  final Widget Function(BuildContext context) fallbackBuilder;
  final VoidCallback? onTap;
}
