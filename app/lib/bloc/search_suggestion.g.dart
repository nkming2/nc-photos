// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_suggestion.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$SearchSuggestionBlocNpLog on SearchSuggestionBloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("bloc.search_suggestion.SearchSuggestionBloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$SearchSuggestionBlocUpdateItemsEventToString
    on SearchSuggestionBlocUpdateItemsEvent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchSuggestionBlocUpdateItemsEvent {items: [length: ${items.length}]}";
  }
}

extension _$SearchSuggestionBlocSearchEventToString
    on SearchSuggestionBlocSearchEvent {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "SearchSuggestionBlocSearchEvent {phrase: $phrase}";
  }
}

extension _$SearchSuggestionBlocStateToString on SearchSuggestionBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "SearchSuggestionBlocState")} {results: [length: ${results.length}]}";
  }
}
