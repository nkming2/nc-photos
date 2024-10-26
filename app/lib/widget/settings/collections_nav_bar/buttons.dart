part of '../collections_nav_bar_settings.dart';

class _NewButton extends StatelessWidget {
  const _NewButton();

  @override
  Widget build(BuildContext context) {
    return HomeCollectionsNavBarButton(
      icon: const Icon(Icons.add_outlined),
      label: L10n.global().createCollectionTooltip,
      isMinimized: true,
      isUseTooltipWhenMinimized: false,
      onPressed: () {},
    );
  }
}

class _SharingButton extends StatelessWidget {
  const _SharingButton({
    required this.isMinimized,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCollectionsNavBarButton(
      icon: const Icon(Icons.share_outlined),
      label: L10n.global().collectionSharingLabel,
      isMinimized: isMinimized,
      isUseTooltipWhenMinimized: false,
      onPressed: () {
        onPressed?.call();
      },
    );
  }

  final bool isMinimized;
  final VoidCallback? onPressed;
}

class _EditedButton extends StatelessWidget {
  const _EditedButton({
    required this.isMinimized,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCollectionsNavBarButton(
      icon: const Icon(Icons.auto_fix_high_outlined),
      label: L10n.global().collectionEditedPhotosLabel,
      isMinimized: isMinimized,
      isUseTooltipWhenMinimized: false,
      onPressed: () {
        onPressed?.call();
      },
    );
  }

  final bool isMinimized;
  final VoidCallback? onPressed;
}

class _ArchiveButton extends StatelessWidget {
  const _ArchiveButton({
    required this.isMinimized,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCollectionsNavBarButton(
      icon: const Icon(Icons.archive_outlined),
      label: L10n.global().albumArchiveLabel,
      isMinimized: isMinimized,
      isUseTooltipWhenMinimized: false,
      onPressed: () {
        onPressed?.call();
      },
    );
  }

  final bool isMinimized;
  final VoidCallback? onPressed;
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({
    required this.isMinimized,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HomeCollectionsNavBarButton(
      icon: const Icon(Icons.delete_outlined),
      label: L10n.global().albumTrashLabel,
      isMinimized: isMinimized,
      isUseTooltipWhenMinimized: false,
      onPressed: () {
        onPressed?.call();
      },
    );
  }

  final bool isMinimized;
  final VoidCallback? onPressed;
}
