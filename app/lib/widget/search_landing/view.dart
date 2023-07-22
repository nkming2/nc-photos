part of '../search_landing.dart';

class _LocationCoverPlaceholder extends StatelessWidget {
  const _LocationCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        Icons.location_on,
        color: Theme.of(context).listPlaceholderForegroundColor,
      ),
    );
  }
}

class _LocationCoverImage extends StatelessWidget {
  const _LocationCoverImage({
    required this.dimension,
    required this.account,
    required this.coverUrl,
  });

  @override
  Widget build(BuildContext context) {
    Widget cover;
    try {
      cover = NetworkRectThumbnail(
        account: account,
        imageUrl: coverUrl!,
        errorBuilder: (_) => const _LocationCoverPlaceholder(),
      );
    } catch (_) {
      cover = const FittedBox(
        child: _LocationCoverPlaceholder(),
      );
    }

    return SizedBox.square(
      dimension: dimension,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(dimension / 2),
        child: Container(
          color: Theme.of(context).listPlaceholderBackgroundColor,
          constraints: const BoxConstraints.expand(),
          child: cover,
        ),
      ),
    );
  }

  final double dimension;
  final Account account;
  final String? coverUrl;
}
