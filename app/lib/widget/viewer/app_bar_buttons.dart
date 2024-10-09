part of '../viewer.dart';

class _AppBarLivePhotoButton extends StatelessWidget {
  const _AppBarLivePhotoButton();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.currentFile != current.currentFile ||
          previous.currentFileState != current.currentFileState,
      builder: (context, state) {
        if (state.currentFile?.let(getLivePhotoTypeFromFile) != null) {
          if (state.currentFileState?.shouldPlayLivePhoto ?? false) {
            return IconButton(
              icon: const Icon(Icons.motion_photos_pause_outlined),
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_PauseLivePhoto(id)));
              },
            );
          } else {
            return IconButton(
              icon: const PngIcon(icMotionPhotosPlay24dp),
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_PlayLivePhoto(id)));
              },
            );
          }
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

class _AppBarFavoriteButton extends StatelessWidget {
  const _AppBarFavoriteButton();

  @override
  Widget build(BuildContext context) {
    return _BlocSelector(
      selector: (state) => state.currentFile,
      builder: (context, currentFile) => currentFile?.fdIsFavorite == true
          ? IconButton(
              icon: const Icon(Icons.star),
              tooltip: L10n.global().unfavoriteTooltip,
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_Unfavorite(id)));
              },
            )
          : IconButton(
              icon: const Icon(Icons.star_border),
              tooltip: L10n.global().favoriteTooltip,
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_Favorite(id)));
              },
            ),
    );
  }
}

class _AppBarShareButton extends StatelessWidget {
  const _AppBarShareButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share_outlined),
      tooltip: L10n.global().shareTooltip,
      onPressed: () {
        context.state.currentFile?.fdId
            .let((id) => context.addEvent(_Share(id)));
      },
    );
  }
}

class _AppBarEditButton extends StatelessWidget {
  const _AppBarEditButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.tune_outlined),
      tooltip: L10n.global().editTooltip,
      onPressed: () {
        context.state.currentFile?.fdId
            .let((id) => context.addEvent(_Edit(id)));
      },
    );
  }
}

class _AppBarEnhanceButton extends StatelessWidget {
  const _AppBarEnhanceButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.auto_fix_high_outlined),
      tooltip: L10n.global().enhanceTooltip,
      onPressed: () {
        context.state.currentFile?.fdId
            .let((id) => context.addEvent(_Enhance(id)));
      },
    );
  }
}

class _AppBarDownloadButton extends StatelessWidget {
  const _AppBarDownloadButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.download_outlined),
      tooltip: L10n.global().downloadTooltip,
      onPressed: () {
        context.state.currentFile?.fdId
            .let((id) => context.addEvent(_Download(id)));
      },
    );
  }
}

class _AppBarDeleteButton extends StatelessWidget {
  const _AppBarDeleteButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outlined),
      tooltip: L10n.global().deleteTooltip,
      onPressed: () {
        context.state.currentFile?.fdId
            .let((id) => context.addEvent(_Delete(id)));
      },
    );
  }
}
