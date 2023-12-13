part of '../places_browser.dart';

@npLog
class _Item {
  _Item({
    required Account account,
    required this.place,
  }) {
    try {
      _coverUrl =
          NetworkRectThumbnail.imageUrlForFileId(account, place.latestFileId);
    } catch (e, stackTrace) {
      _log.warning("[_Item] Failed while imageUrlForFileId", e, stackTrace);
    }
  }

  String get name => place.place;
  String? get coverUrl => _coverUrl;

  final LocationGroup place;

  String? _coverUrl;
}
