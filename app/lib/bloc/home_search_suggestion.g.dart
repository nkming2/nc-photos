// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_search_suggestion.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logHomeSearchSuggestionBloc =
    Logger("bloc.home_search_suggestion.HomeSearchSuggestionBloc");

extension _$HomeSearchSuggestionBlocNpLog on HomeSearchSuggestionBloc {
  // ignore: unused_element
  Logger get _log => _$logHomeSearchSuggestionBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$HomeSearchAlbumResultToString on HomeSearchAlbumResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchAlbumResult {album: $album}";
  }
}

extension _$HomeSearchTagResultToString on HomeSearchTagResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchTagResult {tag: $tag}";
  }
}

extension _$HomeSearchPersonResultToString on HomeSearchPersonResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchPersonResult {person: $person}";
  }
}

extension _$HomeSearchLocationResultToString on HomeSearchLocationResult {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchLocationResult {location: $location}";
  }
}

extension _$HomeSearchSuggestionBlocPreloadDataToString
    on HomeSearchSuggestionBlocPreloadData {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchSuggestionBlocPreloadData {}";
  }
}

extension _$HomeSearchSuggestionBlocSearchToString
    on HomeSearchSuggestionBlocSearch {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchSuggestionBlocSearch {phrase: $phrase}";
  }
}

extension _$HomeSearchSuggestionBlocStateToString
    on HomeSearchSuggestionBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "HomeSearchSuggestionBlocState")} {results: [length: ${results.length}]}";
  }
}

extension _$HomeSearchSuggestionBlocFailureToString
    on HomeSearchSuggestionBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "HomeSearchSuggestionBlocFailure {results: [length: ${results.length}], exception: $exception}";
  }
}
