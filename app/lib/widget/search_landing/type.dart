part of '../search_landing.dart';

@npLog
class _PersonItem {
  _PersonItem(this.person) {
    try {
      _coverUrl = person.getCoverUrl(
        k.photoLargeSize,
        k.photoLargeSize,
        isKeepAspectRatio: true,
      );
    } catch (e, stackTrace) {
      _log.warning("[_PersonItem] Failed while getCoverUrl", e, stackTrace);
    }
  }

  String get name => person.name;
  String? get coverUrl => _coverUrl;

  final Person person;

  String? _coverUrl;
}

@npLog
class _PlaceItem {
  _PlaceItem({
    required Account account,
    required this.place,
  }) {
    try {
      _coverUrl =
          NetworkRectThumbnail.imageUrlForFileId(account, place.latestFileId);
    } catch (e, stackTrace) {
      _log.warning(
          "[_PlaceItem] Failed while imageUrlForFileId", e, stackTrace);
    }
  }

  String get name => place.place;
  String? get coverUrl => _coverUrl;

  final LocationGroup place;

  String? _coverUrl;
}
