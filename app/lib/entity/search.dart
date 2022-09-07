import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/sqlite_table_extension.dart' as sql;
import 'package:nc_photos/iterable_extension.dart';

class SearchCriteria {
  const SearchCriteria(this.input, this.filters);

  SearchCriteria copyWith({
    String? input,
    List<SearchFilter>? filters,
  }) =>
      SearchCriteria(
        input ?? this.input,
        filters ?? List.of(this.filters),
      );

  @override
  toString() => "$runtimeType {"
      "input: $input, "
      "filters: ${filters.toReadableString()}, "
      "}";

  final String input;
  final List<SearchFilter> filters;
}

abstract class SearchFilter {
  void apply(sql.FilesQueryBuilder query);
  bool isSatisfy(File file);
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
  isSatisfy(File file) {
    switch (type) {
      case SearchFileType.image:
        return file_util.isSupportedImageFormat(file);

      case SearchFileType.video:
        return file_util.isSupportedVideoFormat(file);
    }
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
  isSatisfy(File file) => (file.isFavorite ?? false) == value;

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
