part of '../home_collections.dart';

enum HomeCollectionsNavBarButtonType {
  // the order must not be changed
  sharing,
  edited,
  archive,
  trash,
  ;

  static HomeCollectionsNavBarButtonType fromValue(int value) =>
      HomeCollectionsNavBarButtonType.values[value];
}

class _NavigationBar extends StatefulWidget {
  const _NavigationBar();

  @override
  State<StatefulWidget> createState() => _NavigationBarState();
}

class _NavigationBarState extends State<_NavigationBar> {
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController
        .addListener(() => _updateButtonScroll(_scrollController.position));
    _ensureUpdateButtonScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buttons =
        _buttons.map((e) => _buildButton(context, e)).nonNulls.toList();
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: buttons.length,
                    itemBuilder: (context, i) => buttons[i],
                    separatorBuilder: (context, _) => const SizedBox(width: 16),
                  ),
                  if (_hasLeftContent)
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.background,
                                Theme.of(context)
                                    .colorScheme
                                    .background
                                    .withOpacity(0),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_hasRightContent)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      child: IgnorePointer(
                        ignoring: true,
                        child: Container(
                          width: 32,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context)
                                    .colorScheme
                                    .background
                                    .withOpacity(0),
                                Theme.of(context).colorScheme.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const _NavBarNewButton(),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget? _buildButton(
      BuildContext context, HomeCollectionsNavBarButtonType type) {
    switch (type) {
      case HomeCollectionsNavBarButtonType.sharing:
        return const _NavBarSharingButton();
      case HomeCollectionsNavBarButtonType.edited:
        return features.isSupportEnhancement
            ? const _NavBarEditedButton()
            : null;
      case HomeCollectionsNavBarButtonType.archive:
        return const _NavBarArchiveButton();
      case HomeCollectionsNavBarButtonType.trash:
        return const _NavBarTrashButton();
    }
  }

  bool _updateButtonScroll(ScrollPosition pos) {
    if (!pos.hasContentDimensions || !pos.hasPixels) {
      return false;
    }
    if (pos.pixels <= pos.minScrollExtent) {
      if (_hasLeftContent) {
        setState(() {
          _hasLeftContent = false;
        });
      }
    } else {
      if (!_hasLeftContent) {
        setState(() {
          _hasLeftContent = true;
        });
      }
    }
    if (pos.pixels >= pos.maxScrollExtent) {
      if (_hasRightContent) {
        setState(() {
          _hasRightContent = false;
        });
      }
    } else {
      if (!_hasRightContent) {
        setState(() {
          _hasRightContent = true;
        });
      }
    }
    _hasFirstScrollUpdate = true;
    return true;
  }

  void _ensureUpdateButtonScroll() {
    if (_hasFirstScrollUpdate || !mounted) {
      return;
    }
    if (_scrollController.hasClients) {
      if (_updateButtonScroll(_scrollController.position)) {
        return;
      }
    }
    Timer(const Duration(milliseconds: 100), _ensureUpdateButtonScroll);
  }

  static const _buttons = [
    HomeCollectionsNavBarButtonType.sharing,
    HomeCollectionsNavBarButtonType.edited,
    HomeCollectionsNavBarButtonType.archive,
    HomeCollectionsNavBarButtonType.trash,
  ];

  late final ScrollController _scrollController;
  var _hasFirstScrollUpdate = false;
  var _hasLeftContent = false;
  var _hasRightContent = false;
}

class _NavBarButtonIndicator extends StatelessWidget {
  const _NavBarButtonIndicator();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Container(
        width: 4,
        height: 4,
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.isMinimized,
    this.isShowIndicator = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _BlocSelector(
      selector: (state) => state.selectedItems.isEmpty,
      builder: (context, isEnabled) => isMinimized
          ? IconButton.outlined(
              icon: Stack(
                children: [
                  icon,
                  if (isShowIndicator)
                    const Positioned(
                      right: 2,
                      top: 2,
                      child: _NavBarButtonIndicator(),
                    ),
                ],
              ),
              tooltip: label,
              onPressed: isEnabled ? onPressed : null,
            )
          : ActionChip(
              avatar: icon,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (isShowIndicator) ...const [
                    SizedBox(width: 4),
                    _NavBarButtonIndicator(),
                  ],
                ],
              ),
              onPressed: isEnabled ? onPressed : null,
            ),
    );
  }

  final Widget icon;
  final String label;
  final bool isMinimized;
  final bool isShowIndicator;
  final VoidCallback onPressed;
}

@npLog
class _NavBarNewButton extends StatelessWidget {
  const _NavBarNewButton();

  @override
  Widget build(BuildContext context) {
    return _NavBarButton(
      icon: const Icon(Icons.add_outlined),
      label: L10n.global().createCollectionTooltip,
      isMinimized: true,
      onPressed: () async {
        try {
          final collection = await showDialog<Collection>(
            context: context,
            builder: (_) => NewCollectionDialog(
              account: context.bloc.account,
            ),
          );
          if (collection == null) {
            return;
          }
          // Right now we don't have a way to add photos inside the
          // CollectionBrowser, eventually we should add that and remove this
          // branching
          if (collection.isDynamicCollection) {
            // open the newly created collection
            unawaited(Navigator.of(context).pushNamed(
              CollectionBrowser.routeName,
              arguments: CollectionBrowserArguments(collection),
            ));
          }
        } catch (e, stacktrace) {
          _log.shout("[build] Uncaught exception", e, stacktrace);
          context.addEvent(_SetError(AppMessageException(
              L10n.global().createCollectionFailureNotification)));
        }
      },
    );
  }
}

class _NavBarSharingButton extends StatelessWidget {
  const _NavBarSharingButton();

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilderEx(
      stream: context
          .read<AccountController>()
          .accountPrefController
          .hasNewSharedAlbum,
      builder: StreamWidgetBuilder.value(
        (context, hasNewSharedAlbum) => _NavBarButton(
          icon: const Icon(Icons.share_outlined),
          label: L10n.global().collectionSharingLabel,
          isMinimized: false,
          isShowIndicator: hasNewSharedAlbum,
          onPressed: () {
            Navigator.of(context).pushNamed(
              SharingBrowser.routeName,
              arguments: SharingBrowserArguments(context.bloc.account),
            );
          },
        ),
      ),
    );
  }
}

class _NavBarEditedButton extends StatelessWidget {
  const _NavBarEditedButton();

  @override
  Widget build(BuildContext context) {
    return _NavBarButton(
      icon: const Icon(Icons.auto_fix_high_outlined),
      label: L10n.global().collectionEditedPhotosLabel,
      isMinimized: false,
      onPressed: () {
        Navigator.of(context).pushNamed(
          EnhancedPhotoBrowser.routeName,
          arguments: const EnhancedPhotoBrowserArguments(null),
        );
      },
    );
  }
}

class _NavBarArchiveButton extends StatelessWidget {
  const _NavBarArchiveButton();

  @override
  Widget build(BuildContext context) {
    return _NavBarButton(
      icon: const Icon(Icons.archive_outlined),
      label: L10n.global().albumArchiveLabel,
      isMinimized: false,
      onPressed: () {
        Navigator.of(context).pushNamed(ArchiveBrowser.routeName);
      },
    );
  }
}

class _NavBarTrashButton extends StatelessWidget {
  const _NavBarTrashButton();

  @override
  Widget build(BuildContext context) {
    return _NavBarButton(
      icon: const Icon(Icons.delete_outlined),
      label: L10n.global().albumTrashLabel,
      isMinimized: false,
      onPressed: () {
        Navigator.of(context).pushNamed(
          TrashbinBrowser.routeName,
          arguments: TrashbinBrowserArguments(context.bloc.account),
        );
      },
    );
  }
}
