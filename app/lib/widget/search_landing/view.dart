part of '../search_landing.dart';

class _PersonCoverPlaceholder extends StatelessWidget {
  const _PersonCoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Icon(
        Icons.person,
        color: Theme.of(context).listPlaceholderForegroundColor,
      ),
    );
  }
}

class _PersonCoverImage extends StatefulWidget {
  const _PersonCoverImage({
    required this.dimension,
    required this.account,
    required this.coverUrl,
    required this.person,
  });

  @override
  State<StatefulWidget> createState() => _PersonCoverImageState();

  final double dimension;
  final Account account;
  final String? coverUrl;
  final Person person;
}

class _PersonCoverImageState extends State<_PersonCoverImage> {
  @override
  Widget build(BuildContext context) {
    Widget cover;
    try {
      var m = Matrix4.identity();
      if (_layoutSize != null) {
        final ratio = widget.dimension /
            math.min(_layoutSize!.width, _layoutSize!.height);
        final mm = widget.person.getCoverTransform(
          widget.dimension.toInt(),
          (_layoutSize!.width * ratio).toInt(),
          (_layoutSize!.height * ratio).toInt(),
        );
        if (mm != null) {
          m = mm;
        }
      }
      cover = Transform(
        transform: m,
        child: NetworkRectThumbnail(
          account: widget.account,
          imageUrl: widget.coverUrl!,
          errorBuilder: (_) => const _PersonCoverPlaceholder(),
          onSize: (size) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _layoutSize = size;
              });
            });
          },
        ),
      );
    } catch (_) {
      cover = const FittedBox(
        child: _PersonCoverPlaceholder(),
      );
    }

    return SizedBox.square(
      dimension: widget.dimension,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.dimension / 2),
        child: Container(
          color: Theme.of(context).listPlaceholderBackgroundColor,
          constraints: const BoxConstraints.expand(),
          child: cover,
        ),
      ),
    );
  }

  Size? _layoutSize;
}

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
