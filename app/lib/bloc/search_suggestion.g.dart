// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_suggestion.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logSearchSuggestionBloc =
    Logger("bloc.search_suggestion.SearchSuggestionBloc");

extension _$SearchSuggestionBlocNpLog on SearchSuggestionBloc {
  // ignore: unused_element
  Logger get _log => _$logSearchSuggestionBloc;
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
