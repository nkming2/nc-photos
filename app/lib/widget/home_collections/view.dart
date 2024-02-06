part of '../home_collections.dart';

class _ButtonGrid extends StatelessWidget {
  const _ButtonGrid({
    required this.account,
    required this.isEnabled,
    this.onSharingPressed,
    this.onEnhancedPhotosPressed,
    this.onArchivePressed,
    this.onTrashbinPressed,
    this.onNewCollectionPressed,
  });

  @override
  Widget build(BuildContext context) {
    // needed to workaround a scrolling bug when there are more than one
    // SliverStaggeredGrids in a CustomScrollView
    // see: https://github.com/letsar/flutter_staggered_grid_view/issues/98 and
    // https://github.com/letsar/flutter_staggered_grid_view/issues/265
    return SliverToBoxAdapter(
      child: StaggeredGridView.extent(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(0),
        maxCrossAxisExtent: 256,
        staggeredTiles: List.filled(5, const StaggeredTile.fit(1)),
        children: [
          _ButtonGridItemView(
            icon: Icons.share_outlined,
            label: L10n.global().collectionSharingLabel,
            isShowIndicator: AccountPref.of(account).hasNewSharedAlbumOr(),
            isEnabled: isEnabled,
            onTap: () {
              onSharingPressed?.call();
            },
          ),
          if (features.isSupportEnhancement)
            _ButtonGridItemView(
              icon: Icons.auto_fix_high_outlined,
              label: L10n.global().collectionEditedPhotosLabel,
              isEnabled: isEnabled,
              onTap: () {
                onEnhancedPhotosPressed?.call();
              },
            ),
          _ButtonGridItemView(
            icon: Icons.archive_outlined,
            label: L10n.global().albumArchiveLabel,
            isEnabled: isEnabled,
            onTap: () {
              onArchivePressed?.call();
            },
          ),
          _ButtonGridItemView(
            icon: Icons.delete_outlined,
            label: L10n.global().albumTrashLabel,
            isEnabled: isEnabled,
            onTap: () {
              onTrashbinPressed?.call();
            },
          ),
          _ButtonGridItemView(
            icon: Icons.add,
            label: L10n.global().createCollectionTooltip,
            isEnabled: isEnabled,
            onTap: () {
              onNewCollectionPressed?.call();
            },
          ),
        ],
      ),
    );
  }

  final Account account;
  final bool isEnabled;
  final VoidCallback? onSharingPressed;
  final VoidCallback? onEnhancedPhotosPressed;
  final VoidCallback? onArchivePressed;
  final VoidCallback? onTrashbinPressed;
  final VoidCallback? onNewCollectionPressed;
}

class _ButtonGridItemView extends StatelessWidget {
  const _ButtonGridItemView({
    required this.icon,
    required this.label,
    this.isShowIndicator = false,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ActionChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
        // specify icon size explicitly to workaround size flickering during
        // theme transition
        avatar: Icon(icon, size: 18),
        label: Row(
          children: [
            Expanded(
              child: Text(label),
            ),
            if (isShowIndicator)
              Icon(
                Icons.circle,
                color: Theme.of(context).colorScheme.tertiary,
                size: 8,
              ),
          ],
        ),
        onPressed: isEnabled ? onTap : null,
      ),
    );
  }

  final IconData icon;
  final String label;
  final bool isShowIndicator;
  final bool isEnabled;
  final VoidCallback? onTap;
}

class _ItemView extends StatelessWidget {
  const _ItemView({
    required this.account,
    required this.item,
    this.collectionItemCountOverride,
  });

  @override
  Widget build(BuildContext context) {
    Widget? icon;
    switch (item.itemType) {
      case _ItemType.ncAlbum:
        icon = const Icon(Icons.cloud);
        break;
      case _ItemType.album:
        icon = null;
        break;
      case _ItemType.tagAlbum:
        icon = const Icon(Icons.local_offer);
        break;
      case _ItemType.dirAlbum:
        icon = const Icon(Icons.folder);
        break;
    }
    var subtitle = "";
    if (item.isShared) {
      subtitle = "${L10n.global().albumSharedLabel} | ";
    }
    subtitle +=
        item.getSubtitle(itemCountOverride: collectionItemCountOverride) ?? "";
    return CollectionGridItem(
      cover: _CollectionCover(
        account: account,
        url: item.coverUrl,
      ),
      title: item.name,
      subtitle: subtitle,
      icon: icon,
    );
  }

  final Account account;
  final _Item item;
  final int? collectionItemCountOverride;
}

class _CollectionCover extends StatelessWidget {
  const _CollectionCover({
    required this.account,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: Theme.of(context).listPlaceholderBackgroundColor,
        constraints: const BoxConstraints.expand(),
        child: url != null
            ? FittedBox(
                clipBehavior: Clip.hardEdge,
                fit: BoxFit.cover,
                child: CachedNetworkImage(
                  cacheManager: CoverCacheManager.inst,
                  imageUrl: url!,
                  httpHeaders: {
                    "Authorization":
                        AuthUtil.fromAccount(account).toHeaderValue(),
                  },
                  fadeInDuration: const Duration(),
                  filterQuality: FilterQuality.high,
                  errorWidget: (context, url, error) {
                    // just leave it empty
                    return Container();
                  },
                  imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                ),
              )
            : Icon(
                Icons.panorama,
                color: Theme.of(context).listPlaceholderForegroundColor,
                size: 88,
              ),
      ),
    );
  }

  final Account account;
  final String? url;
}
