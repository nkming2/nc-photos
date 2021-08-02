import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/album_search.dart';
import 'package:nc_photos/bloc/album_search_suggestion.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/list_album.dart';
import 'package:nc_photos/widget/builder/album_grid_item_builder.dart';
import 'package:nc_photos/widget/empty_list_indicator.dart';

/// Search and filter albums (to be replaced by a more universal search in the
/// future)
class AlbumSearchDelegate extends SearchDelegate {
  AlbumSearchDelegate(BuildContext context, this.account)
      : super(
          searchFieldLabel: L10n.of(context).albumSearchTextFieldHint,
        ) {
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    ListAlbum(fileRepo, albumRepo)(account).toList().then((value) {
      final albums = value.whereType<Album>().toList();
      _searchBloc.add(AlbumSearchBlocUpdateItemsEvent(albums));
      _suggestionBloc.add(AlbumSearchSuggestionBlocUpdateItemsEvent(albums));
    });
  }

  @override
  ThemeData appBarTheme(BuildContext context) =>
      AppTheme.buildThemeData(context);

  @override
  buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        tooltip: L10n.of(context).clearTooltip,
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
    _suggestionBloc.add(AlbumSearchSuggestionBlocSearchEvent(query));
    return BlocBuilder<AlbumSearchSuggestionBloc,
        AlbumSearchSuggestionBlocState>(
      bloc: _suggestionBloc,
      builder: _buildSuggestionContent,
    );
  }

  Widget _buildResultContent(BuildContext context, AlbumSearchBlocState state) {
    if (state.results.isEmpty) {
      return EmptyListIndicator(
        icon: Icons.mood_bad,
        text: L10n.of(context).listNoResultsText,
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
    return AlbumGridItemBuilder(
      account: account,
      album: album,
      onTap: () {
        close(context, album);
      },
    ).build(context);
  }

  Widget _buildSuggestionContent(
      BuildContext context, AlbumSearchSuggestionBlocState state) {
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
  final _suggestionBloc = AlbumSearchSuggestionBloc();
}
