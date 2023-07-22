part of '../search_landing.dart';

class _LandingPersonItem {
  _LandingPersonItem({
    required this.account,
    required this.person,
    this.onTap,
  })  : name = person.name,
        faceUrl = person.getCoverUrl(
          k.photoLargeSize,
          k.photoLargeSize,
          isKeepAspectRatio: true,
        );

  Widget buildWidget(BuildContext context) => _LandingPersonWidget(
        account: account,
        person: person,
        label: name,
        coverUrl: faceUrl,
        onTap: onTap,
      );

  final Account account;
  final Person person;
  final String name;
  final String? faceUrl;
  final VoidCallback? onTap;
}

class _LandingLocationItem {
  const _LandingLocationItem({
    required this.account,
    required this.name,
    required this.thumbUrl,
    this.onTap,
  });

  Widget buildWidget(BuildContext context) => _LandingLocationWidget(
        account: account,
        label: name,
        coverUrl: thumbUrl,
        onTap: onTap,
      );

  final Account account;
  final String name;
  final String thumbUrl;
  final VoidCallback? onTap;
}
