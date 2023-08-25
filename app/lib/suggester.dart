import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_string/np_string.dart';
import 'package:tuple/tuple.dart';
import 'package:woozy_search/woozy_search.dart';

part 'suggester.g.dart';

@npLog
class Suggester<T> {
  Suggester({
    required this.items,
    required this.itemToKeywords,
    int maxResult = 5,
  }) : _searcher = Woozy(limit: maxResult) {
    for (final a in items) {
      for (final k in itemToKeywords(a)) {
        _searcher.addEntry(k.toCaseInsensitiveString(), value: a);
      }
    }
  }

  List<T> search(CiString phrase) {
    final results = _searcher.search(phrase.toCaseInsensitiveString());
    if (kDebugMode) {
      final str = results.map((e) => "${e.score}: ${e.text}").join("\n");
      _log.info("[search] Search '$phrase':\n$str");
    }
    final matches = results
        .where((e) => e.score > 0)
        .map((e) {
          if (itemToKeywords(e.value as T).any((k) => k.startsWith(phrase))) {
            // prefer names that start exactly with the search phrase
            return Tuple2(e.score + 1, e.value as T);
          } else {
            return Tuple2(e.score, e.value as T);
          }
        })
        .sorted((a, b) => a.item1.compareTo(b.item1))
        .reversed
        .distinctIf(
          (a, b) => identical(a.item2, b.item2),
          (a) => a.item2.hashCode,
        )
        .map((e) => e.item2)
        .toList();
    return matches;
  }

  final List<T> items;
  final List<CiString> Function(T item) itemToKeywords;

  final Woozy _searcher;
}
