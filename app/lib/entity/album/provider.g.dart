// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provider.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$AlbumProviderNpLog on AlbumProvider {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("entity.album.provider.AlbumProvider");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$AlbumStaticProviderToString on AlbumStaticProvider {
  String _$toString({bool isDeep = false}) {
    // ignore: unnecessary_string_interpolations
    return "AlbumStaticProvider {latestItemTime: $latestItemTime, items: ${isDeep ? items.toReadableString() : '[length: ${items.length}]'}}";
  }
}

extension _$AlbumDirProviderToString on AlbumDirProvider {
  String _$toString({bool isDeep = false}) {
    // ignore: unnecessary_string_interpolations
    return "AlbumDirProvider {latestItemTime: $latestItemTime, dirs: ${dirs.map((e) => e.path).toReadableString()}}";
  }
}

extension _$AlbumTagProviderToString on AlbumTagProvider {
  String _$toString({bool isDeep = false}) {
    // ignore: unnecessary_string_interpolations
    return "AlbumTagProvider {latestItemTime: $latestItemTime, tags: ${tags.map((t) => t.displayName).toReadableString()}}";
  }
}
