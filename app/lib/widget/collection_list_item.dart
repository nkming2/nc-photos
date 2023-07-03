import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/network_thumbnail.dart';

class CollectionListSmall extends StatelessWidget {
  const CollectionListSmall({
    Key? key,
    required this.account,
    required this.label,
    required this.coverUrl,
    required this.fallbackBuilder,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    Widget content = Stack(
      children: [
        SizedBox.expand(
          child: _buildCoverImage(context),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 24,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0),
                      Colors.black.withOpacity(.5),
                    ],
                  ),
                ),
              ),
              Container(
                color: Colors.black.withOpacity(.5),
                constraints: const BoxConstraints(minWidth: double.infinity),
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge!.copyWith(
                        color: Theme.of(context).onDarkSurface,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    if (onTap != null) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
              ),
            ),
          ),
        ],
      );
    }
    return Container(
      color: Theme.of(context).listPlaceholderBackgroundColor,
      constraints: const BoxConstraints.expand(),
      child: content,
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    Widget buildPlaceholder() => Padding(
          padding: const EdgeInsets.all(8),
          child: fallbackBuilder(context),
        );
    try {
      return NetworkRectThumbnail(
        account: account,
        imageUrl: coverUrl!,
        errorBuilder: (_) => buildPlaceholder(),
      );
    } catch (_) {
      return FittedBox(
        child: buildPlaceholder(),
      );
    }
  }

  final Account account;
  final String label;
  final String? coverUrl;
  final Widget Function(BuildContext context) fallbackBuilder;
  final VoidCallback? onTap;
}
