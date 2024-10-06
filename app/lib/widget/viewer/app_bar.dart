part of '../viewer.dart';

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    final isTitleCentered = getRawPlatform() == NpPlatform.iOs;
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.isDetailPaneActive != current.isDetailPaneActive ||
          previous.isZoomed != current.isZoomed,
      builder: (context, state) => AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.isDetailPaneActive != current.isDetailPaneActive ||
              previous.currentFile != current.currentFile,
          builder: (context, state) =>
              !state.isDetailPaneActive && state.currentFile != null
                  ? _AppBarTitle(
                      file: state.currentFile!,
                      isCentered: isTitleCentered,
                    )
                  : const SizedBox.shrink(),
        ),
        titleSpacing: 0,
        centerTitle: isTitleCentered,
        actions: !state.isDetailPaneActive && !state.isZoomed
            ? [
                _BlocBuilder(
                  buildWhen: (previous, current) =>
                      previous.currentFile != current.currentFile ||
                      previous.currentFileState != current.currentFileState,
                  builder: (context, state) {
                    if (state.currentFile?.let(getLivePhotoTypeFromFile) !=
                        null) {
                      if (state.currentFileState?.shouldPlayLivePhoto ??
                          false) {
                        return IconButton(
                          icon: const Icon(Icons.motion_photos_pause_outlined),
                          onPressed: () {
                            context.state.currentFile?.fdId.let(
                                (id) => context.addEvent(_PauseLivePhoto(id)));
                          },
                        );
                      } else {
                        return IconButton(
                          icon: const PngIcon(icMotionPhotosPlay24dp),
                          onPressed: () {
                            context.state.currentFile?.fdId.let(
                                (id) => context.addEvent(_PlayLivePhoto(id)));
                          },
                        );
                      }
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),
                _BlocSelector(
                  selector: (state) => state.currentFile,
                  builder: (context, currentFile) => currentFile
                              ?.fdIsFavorite ==
                          true
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
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: L10n.global().detailsTooltip,
                  onPressed: () {
                    context.addEvent(const _OpenDetailPane(true));
                  },
                ),
              ]
            : null,
      ),
    );
  }
}

class _AppBarTitle extends StatelessWidget {
  const _AppBarTitle({
    required this.file,
    required this.isCentered,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final localTime = file.fdDateTime.toLocal();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(
          (localTime.year == DateTime.now().year
                  ? DateFormat.MMMd(locale)
                  : DateFormat.yMMMd(locale))
              .format(localTime),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          DateFormat.jm(locale).format(localTime),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  final FileDescriptor file;
  final bool isCentered;
}

class _BottomAppBar extends StatelessWidget {
  const _BottomAppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(0, -1),
          end: Alignment(0, 1),
          colors: [
            Color.fromARGB(0, 0, 0, 0),
            Color.fromARGB(192, 0, 0, 0),
          ],
        ),
      ),
      child: _BlocBuilder(
        buildWhen: (previous, current) =>
            previous.currentFile != current.currentFile ||
            previous.collection != current.collection,
        builder: (context, state) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: L10n.global().shareTooltip,
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_Share(id)));
              },
            ),
            if (features.isSupportEnhancement &&
                state.currentFile?.let(ImageEnhancer.isSupportedFormat) ==
                    true) ...[
              IconButton(
                icon: const Icon(Icons.tune_outlined),
                tooltip: L10n.global().editTooltip,
                onPressed: () {
                  context.state.currentFile?.fdId
                      .let((id) => context.addEvent(_Edit(id)));
                },
              ),
              IconButton(
                icon: const Icon(Icons.auto_fix_high_outlined),
                tooltip: L10n.global().enhanceTooltip,
                onPressed: () {
                  context.state.currentFile?.fdId
                      .let((id) => context.addEvent(_Enhance(id)));
                },
              ),
            ],
            IconButton(
              icon: const Icon(Icons.download_outlined),
              tooltip: L10n.global().downloadTooltip,
              onPressed: () {
                context.state.currentFile?.fdId
                    .let((id) => context.addEvent(_Download(id)));
              },
            ),
            if (state.collection == null)
              IconButton(
                icon: const Icon(Icons.delete_outlined),
                tooltip: L10n.global().deleteTooltip,
                onPressed: () {
                  context.state.currentFile?.fdId
                      .let((id) => context.addEvent(_Delete(id)));
                },
              ),
          ]
              .map((e) => Expanded(
                    flex: 1,
                    child: e,
                  ))
              .toList(),
        ),
      ),
    );
  }
}
