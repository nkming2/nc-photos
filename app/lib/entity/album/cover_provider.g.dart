// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cover_provider.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logAlbumCoverProvider =
    Logger("entity.album.cover_provider.AlbumCoverProvider");

extension _$AlbumCoverProviderNpLog on AlbumCoverProvider {
  // ignore: unused_element
  Logger get _log => _$logAlbumCoverProvider;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$AlbumAutoCoverProviderToString on AlbumAutoCoverProvider {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumAutoCoverProvider {coverFile: ${coverFile == null ? null : "${coverFile!.path}"}}";
  }
}

extension _$AlbumManualCoverProviderToString on AlbumManualCoverProvider {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumManualCoverProvider {coverFile: ${coverFile.path}}";
  }
}

extension _$AlbumMemoryCoverProviderToString on AlbumMemoryCoverProvider {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "AlbumMemoryCoverProvider {coverFile: ${coverFile.fdPath}}";
  }
}
