import 'package:nc_photos/account.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';

class SearchCriteria {
  const SearchCriteria(this.keywords, this.filters);

  SearchCriteria copyWith({
    Set<CiString>? keywords,
    List<SearchFilter>? filters,
  }) =>
      SearchCriteria(
        keywords ?? Set.of(this.keywords),
        filters ?? List.of(this.filters),
      );

  @override
  toString() => "$runtimeType {"
      "keywords: ${keywords.toReadableString()}, "
      "filters: ${filters.toReadableString()}, "
      "}";

  final Set<CiString> keywords;
  final List<SearchFilter> filters;
}

abstract class SearchFilter {
  void apply(sql.FilesQueryBuilder query);
}

enum SearchFileType {
  image,
  video,
}

extension on SearchFileType {
  String toSqlPattern() {
    switch (this) {
      case SearchFileType.image:
        return "image/%";

      case SearchFileType.video:
        return "video/%";
    }
  }
}

class SearchFileTypeFilter implements SearchFilter {
  const SearchFileTypeFilter(this.type);

  @override
  apply(sql.FilesQueryBuilder query) {
    query.byMimePattern(type.toSqlPattern());
  }

  @override
  toString() => "$runtimeType {"
      "type: ${type.name}, "
      "}";

  final SearchFileType type;
}

class SearchFavoriteFilter implements SearchFilter {
  const SearchFavoriteFilter(this.value);

  @override
  apply(sql.FilesQueryBuilder query) {
    query.byFavorite(value);
  }

  @override
  toString() => "$runtimeType {"
      "value: $value, "
      "}";

  final bool value;
}

class SearchRepo {
  const SearchRepo(this.dataSrc);

  Future<List<File>> list(Account account, SearchCriteria criteria) =>
      dataSrc.list(account, criteria);

  final SearchDataSource dataSrc;
}

abstract class SearchDataSource {
  /// List all results from a given search criteria
  Future<List<File>> list(Account account, SearchCriteria criteria);
}
