import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/home_search_suggestion.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/list_location_group.dart';
import 'package:nc_photos/widget/album_browser_util.dart' as album_browser_util;
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/person_browser.dart';
import 'package:nc_photos/widget/place_browser.dart';
import 'package:nc_photos/widget/tag_browser.dart';
import 'package:np_codegen/np_codegen.dart';

part 'home_search_suggestion.g.dart';

class HomeSearchSuggestionController {
  void search(String phrase) {
    _bloc?.add(HomeSearchSuggestionBlocSearch(phrase.toCi()));
  }

  HomeSearchSuggestionBloc? _bloc;
}

class HomeSearchSuggestion extends StatefulWidget {
  const HomeSearchSuggestion({
    Key? key,
    required this.account,
    required this.controller,
  }) : super(key: key);

  @override
  createState() => _HomeSearchSuggestionState();

  final Account account;
  final HomeSearchSuggestionController controller;
}

@npLog
class _HomeSearchSuggestionState extends State<HomeSearchSuggestion>
    with RouteAware, PageVisibilityMixin {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return BlocListener<HomeSearchSuggestionBloc,
        HomeSearchSuggestionBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child:
          BlocBuilder<HomeSearchSuggestionBloc, HomeSearchSuggestionBlocState>(
        bloc: _bloc,
        builder: (context, state) => Theme(
          data: Theme.of(context).run((t) {
            return t.copyWith(
              listTileTheme: ListTileThemeData(
                iconColor: t.colorScheme.onBackground,
                textColor: t.colorScheme.onBackground,
              ),
            );
          }),
          child: _buildContent(context, state),
        ),
      ),
    );
  }

  void _initBloc() {
    _bloc =
        (widget.controller._bloc ??= HomeSearchSuggestionBloc(widget.account));
    if (_bloc.state is! HomeSearchSuggestionBlocInit) {
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

  Widget _buildContent(
      BuildContext context, HomeSearchSuggestionBlocState state) {
    if (_items.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _items.map((e) => e.buildWidget(context)).toList(),
        ),
      );
    }
  }

  void _onStateChange(
      BuildContext context, HomeSearchSuggestionBlocState state) {
    if (state is HomeSearchSuggestionBlocInit) {
      _items = [];
    } else if (state is HomeSearchSuggestionBlocSuccess ||
        state is HomeSearchSuggestionBlocLoading) {
      _transformItems(state.results);
    } else if (state is HomeSearchSuggestionBlocFailure) {
      _transformItems(state.results);
      if (isPageVisible()) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(state.exception)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
  }

  void _onAlbumPressed(_AlbumListItem item) {
    if (mounted) {
      album_browser_util.push(context, widget.account, item.album);
    }
  }

  void _onTagPressed(_TagListItem item) {
    if (mounted) {
      Navigator.of(context).pushNamed(TagBrowser.routeName,
          arguments: TagBrowserArguments(widget.account, item.tag));
    }
  }

  void _onPersonPressed(_PersonListItem item) {
    if (mounted) {
      Navigator.of(context).pushNamed(PersonBrowser.routeName,
          arguments: PersonBrowserArguments(widget.account, item.person));
    }
  }

  void _onLocationPressed(_LocationListItem item) {
    if (mounted) {
      Navigator.of(context).pushNamed(PlaceBrowser.routeName,
          arguments: PlaceBrowserArguments(
              widget.account, item.location.place, item.location.countryCode));
    }
  }

  void _transformItems(List<HomeSearchResult> results) {
    final items = () sync* {
      for (final r in results) {
        if (r is HomeSearchAlbumResult) {
          yield _AlbumListItem(r.album, onTap: _onAlbumPressed);
        } else if (r is HomeSearchTagResult) {
          yield _TagListItem(r.tag, onTap: _onTagPressed);
        } else if (r is HomeSearchPersonResult) {
          yield _PersonListItem(r.person, onTap: _onPersonPressed);
        } else if (r is HomeSearchLocationResult) {
          yield _LocationListItem(r.location, onTap: _onLocationPressed);
        } else {
          _log.warning("[_transformItems] Unknown type: ${r.runtimeType}");
        }
      }
    }()
        .toList();
    _items = items;
  }

  late final HomeSearchSuggestionBloc _bloc;

  var _items = <_ListItem>[];
}

abstract class _ListItem {
  Widget buildWidget(BuildContext context);
}

class _AlbumListItem implements _ListItem {
  const _AlbumListItem(
    this.album, {
    this.onTap,
  });

  @override
  buildWidget(BuildContext context) => ListTile(
        leading: const Icon(Icons.photo_album_outlined),
        title: Text(album.name),
        onTap: onTap == null ? null : () => onTap!(this),
      );

  final Album album;
  final void Function(_AlbumListItem)? onTap;
}

class _TagListItem implements _ListItem {
  const _TagListItem(
    this.tag, {
    this.onTap,
  });

  @override
  buildWidget(BuildContext context) => ListTile(
        leading: const Icon(Icons.local_offer_outlined),
        title: Text(tag.displayName),
        onTap: onTap == null ? null : () => onTap!(this),
      );

  final Tag tag;
  final void Function(_TagListItem)? onTap;
}

class _PersonListItem implements _ListItem {
  const _PersonListItem(
    this.person, {
    this.onTap,
  });

  @override
  buildWidget(BuildContext context) => ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(person.name),
        onTap: onTap == null ? null : () => onTap!(this),
      );

  final Person person;
  final void Function(_PersonListItem)? onTap;
}

class _LocationListItem implements _ListItem {
  const _LocationListItem(
    this.location, {
    this.onTap,
  });

  @override
  buildWidget(BuildContext context) => ListTile(
        leading: const Icon(Icons.location_on_outlined),
        title: Text(location.place),
        onTap: onTap == null ? null : () => onTap!(this),
      );

  final LocationGroup location;
  final void Function(_LocationListItem)? onTap;
}
