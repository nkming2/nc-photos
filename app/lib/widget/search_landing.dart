import 'dart:math' as math;

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/search_landing.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection/builder.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:nc_photos/widget/collection_browser.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';
import 'package:nc_photos/widget/people_browser.dart';
import 'package:nc_photos/widget/places_browser.dart';
import 'package:nc_photos/widget/settings/account_settings.dart';
import 'package:np_codegen/np_codegen.dart';

part 'search_landing.g.dart';
part 'search_landing/type.dart';
part 'search_landing/view.dart';

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
        if (context
                .read<AccountController>()
                .accountPrefController
                .personProvider
                .value !=
            PersonProvider.none)
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
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AccountSettings.routeName,
                        arguments: const AccountSettingsArguments(
                          highlight: AccountSettingsOption.personProvider,
                        ),
                      );
                    },
                    tooltip: L10n.global().accountSettingsTooltip,
                    icon: const Icon(Icons.settings_outlined),
                  ),
                  IconButton(
                    onPressed: () {
                      launch(help_util.peopleUrl);
                    },
                    tooltip: L10n.global().helpTooltip,
                    icon: const Icon(Icons.help_outline),
                  ),
                ],
              )
            : TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(PeopleBrowser.routeName);
                },
                child: Text(L10n.global().showAllButtonLabel),
              ),
      ),
      if (isNoResult)
        SizedBox(
          height: 48,
          child: Center(
            child: Text(L10n.global().searchLandingPeopleListEmptyText2),
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
    Navigator.pushNamed(
      context,
      CollectionBrowser.routeName,
      arguments: CollectionBrowserArguments(
        CollectionBuilder.byPerson(widget.account, person),
      ),
    );
  }

  void _onLocationItemTap(LocationGroup location) {
    Navigator.of(context).pushNamed(
      CollectionBrowser.routeName,
      arguments: CollectionBrowserArguments(
        CollectionBuilder.byLocationGroup(widget.account, location),
      ),
    );
  }

  void _transformItems(List<Person> persons, LocationGroupResult locations) {
    _transformPersons(persons);
    _transformLocations(locations);
  }

  void _transformPersons(List<Person> persons) {
    _personItems = persons
        .sorted((a, b) {
          final countCompare = (b.count ?? 0).compareTo(a.count ?? 0);
          if (countCompare == 0) {
            return a.name.compareTo(b.name);
          } else {
            return countCompare;
          }
        })
        .take(10)
        .map((e) => _LandingPersonItem(
              account: widget.account,
              person: e,
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
              thumbUrl: NetworkRectThumbnail.imageUrlForFileId(
                  widget.account, e.latestFileId),
              onTap: () => _onLocationItemTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(SearchLandingBlocQuery(widget.account, _accountPrefController));
  }

  late final _bloc = SearchLandingBloc(KiwiContainer().resolve<DiContainer>());
  late final _accountPrefController =
      context.read<AccountController>().accountPrefController;

  var _personItems = <_LandingPersonItem>[];
  var _locationItems = <_LandingLocationItem>[];
}

class _LandingPersonWidget extends StatelessWidget {
  const _LandingPersonWidget({
    required this.account,
    required this.person,
    required this.label,
    required this.coverUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: _PersonCoverImage(
              dimension: 72,
              account: account,
              person: person,
              coverUrl: coverUrl,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Label(label: label)),
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

  final Account account;
  final Person person;
  final String label;
  final String? coverUrl;
  final VoidCallback? onTap;
}

class _LandingLocationWidget extends StatelessWidget {
  const _LandingLocationWidget({
    required this.account,
    required this.label,
    required this.coverUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: _LocationCoverImage(
              dimension: 72,
              account: account,
              coverUrl: coverUrl,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _Label(label: label)),
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

  final Account account;
  final String label;
  final String? coverUrl;
  final VoidCallback? onTap;
}

class _Label extends StatelessWidget {
  const _Label({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Text(
        label + "\n",
        style: Theme.of(context).textTheme.bodyMedium,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  final String label;
}
