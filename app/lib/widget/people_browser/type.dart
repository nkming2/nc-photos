part of '../people_browser.dart';

@npLog
class _Item {
  _Item(this.person) {
    try {
      _coverUrl = person.getCoverUrl(k.coverSize, k.coverSize);
    } catch (e, stackTrace) {
      _log.warning("[_Item] Failed while getCoverUrl", e, stackTrace);
    }
  }

  String get name => person.name;

  String? get coverUrl => _coverUrl;

  final Person person;

  String? _coverUrl;
}
