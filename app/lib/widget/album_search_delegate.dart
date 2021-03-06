import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/album_search.dart';
import 'package:nc_photos/bloc/search_suggestion.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';

/// Search and filter albums (to be replaced by a more universal search in the
/// future)
class AlbumSearchDelegate extends SearchDelegate {
  AlbumSearchDelegate(BuildContext context, this.account)
      : super(
          searchFieldLabel: L10n.global().albumSearchTextFieldHint,
        ) {
    ListAlbum(KiwiContainer().resolve<DiContainer>())(account)
        .toList()
        .then((value) {
      final albums = value.whereType<Album>().toList();
      _searchBloc.add(AlbumSearchBlocUpdateItemsEvent(albums));
      _suggestionBloc.add(SearchSuggestionBlocUpdateItemsEvent<Album>(albums));
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) =>
      AppTheme.buildThemeData(context);

  @override
  buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        tooltip: L10n.global().clearTooltip,
        onPressed: () {
          query = "";
        },
      ),
    ];
  }

  @override
  buildLeading(BuildContext context) {
    return BackButton(
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  buildResults(BuildContext context) {
    _searchBloc.add(AlbumSearchBlocSearchEvent(query));
    return BlocBuilder<AlbumSearchBloc, AlbumSearchBlocState>(
      bloc: _searchBloc,
      builder: _buildResultContent,
    );
  }

  @override
  buildSuggestions(BuildContext context) {
    _suggestionBloc.add(SearchSuggestionBlocSearchEvent<Album>(query.toCi()));
    return BlocBuilder<SearchSuggestionBloc<Album>,
        SearchSuggestionBlocState<Album>>(
      bloc: _suggestionBloc,
      builder: _buildSuggestionContent,
    );
  }

  Widget _buildResultContent(BuildContext context, AlbumSearchBlocState state) {
    if (state.results.isEmpty) {
      return EmptyListIndicator(
        icon: Icons.mood_bad,
        text: L10n.global().listNoResultsText,
      );
    } else {
      return StaggeredGridView.extentBuilder(
        maxCrossAxisExtent: 256,
        mainAxisSpacing: 8,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: state.results.length,
        itemBuilder: (contex, index) =>
            _buildResultItem(context, state.results[index]),
        staggeredTileBuilder: (_) => const StaggeredTile.count(1, 1),
      );
    }
  }

  Widget _buildResultItem(BuildContext context, Album album) {
    return Stack(
      children: [
        AlbumGridItemBuilder(
          account: account,
          album: album,
        ).build(context),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {
                close(context, album);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionContent(
      BuildContext context, SearchSuggestionBlocState<Album> state) {
    return SingleChildScrollView(
      child: Column(
        children: state.results
            .map((e) => ListTile(
                  title: Text(e.name),
                  onTap: () {
                    query = e.name;
                    showResults(context);
                  },
                ))
            .toList(),
      ),
    );
  }

  final Account account;

  final _searchBloc = AlbumSearchBloc();
  final _suggestionBloc = SearchSuggestionBloc<Album>(
    itemToKeywords: (item) => [item.name.toCi()],
  );
}
