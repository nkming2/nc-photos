part of '../collection_browser.dart';

class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    // capability can't be changed once the collection is created
    final capabilities = context.read<_Bloc>().state.collection.capabilities;
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: const _AppBarCover(),
        title: _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.collection.name != current.collection.name,
          builder: (context, state) => Text(
            state.collection.name,
            style: TextStyle(
              color: Theme.of(context).appBarTheme.foregroundColor,
            ),
          ),
        ),
      ),
      actions: [
        ZoomMenuButton(
          initialZoom: 0,
          minZoom: 0,
          maxZoom: 2,
          onZoomChanged: (value) {
            context.read<PrefController>().setAlbumBrowserZoomLevel(value);
          },
        ),
        if (capabilities.contains(CollectionCapability.rename))
          _BlocBuilder(
            buildWhen: (previous, current) => previous.items != current.items,
            builder: (context, state) => PopupMenuButton<_MenuOption>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              itemBuilder: (context) {
                return [
                  if (capabilities.contains(CollectionCapability.rename))
                    PopupMenuItem(
                      value: _MenuOption.edit,
                      child: Text(L10n.global().editTooltip),
                    ),
                  if (state.items.isNotEmpty)
                    PopupMenuItem(
                      value: _MenuOption.download,
                      child: Text(L10n.global().downloadTooltip),
                    ),
                ];
              },
              onSelected: (option) {
                _onMenuSelected(context, option);
              },
            ),
          ),
      ],
    );
  }

  void _onMenuSelected(BuildContext context, _MenuOption option) {
    switch (option) {
      case _MenuOption.edit:
        context.read<_Bloc>().add(const _BeginEdit());
        break;
      case _MenuOption.download:
        context.read<_Bloc>().add(const _Download());
        break;
    }
  }
}

class _AppBarCover extends StatelessWidget {
  const _AppBarCover();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) => previous.coverUrl != current.coverUrl,
      builder: (context, state) {
        if (state.coverUrl != null) {
          return Opacity(
            opacity:
                Theme.of(context).brightness == Brightness.light ? 0.25 : 0.35,
            child: FittedBox(
              clipBehavior: Clip.hardEdge,
              fit: BoxFit.cover,
              child: CachedNetworkImage(
                cacheManager: CoverCacheManager.inst,
                imageUrl: state.coverUrl!,
                httpHeaders: {
                  "Authorization":
                      AuthUtil.fromAccount(context.read<_Bloc>().account)
                          .toHeaderValue(),
                },
                fadeInDuration: const Duration(),
                filterQuality: FilterQuality.high,
                errorWidget: (context, url, error) {
                  // just leave it empty
                  return Container();
                },
                imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}

@npLog
class _SelectionAppBar extends StatelessWidget {
  const _SelectionAppBar();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.selectedItems != current.selectedItems,
      builder: (context, state) => SelectionAppBar(
        count: state.selectedItems.length,
        onClosePressed: () {
          context.read<_Bloc>().add(const _SetSelectedItems(items: {}));
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: L10n.global().shareTooltip,
            onPressed: () {
              _onSelectionSharePressed(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_outlined),
            tooltip: L10n.global().addToAlbumTooltip,
            onPressed: () {
              _onSelectionAddPressed(context);
            },
          ),
          PopupMenuButton<_SelectionMenuOption>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (context) => [
              if (state.collection.capabilities
                      .contains(CollectionCapability.manualItem) &&
                  state.isSelectionRemovable)
                PopupMenuItem(
                  value: _SelectionMenuOption.removeFromAlbum,
                  child: Text(L10n.global().removeFromAlbumTooltip),
                ),
              PopupMenuItem(
                value: _SelectionMenuOption.download,
                child: Text(L10n.global().downloadTooltip),
              ),
              if (state.isSelectionManageableFile) ...[
                PopupMenuItem(
                  value: _SelectionMenuOption.archive,
                  child: Text(L10n.global().archiveTooltip),
                ),
                PopupMenuItem(
                  value: _SelectionMenuOption.delete,
                  child: Text(L10n.global().deleteTooltip),
                ),
              ],
            ],
            onSelected: (option) {
              _onSelectionMenuSelected(context, option);
            },
          ),
        ],
      ),
    );
  }

  void _onSelectionMenuSelected(
      BuildContext context, _SelectionMenuOption option) {
    switch (option) {
      case _SelectionMenuOption.download:
        context.read<_Bloc>().add(const _DownloadSelectedItems());
        break;
      case _SelectionMenuOption.removeFromAlbum:
        context.read<_Bloc>().add(const _RemoveSelectedItemsFromCollection());
        break;
      case _SelectionMenuOption.archive:
        context.read<_Bloc>().add(const _ArchiveSelectedItems());
        break;
      case _SelectionMenuOption.delete:
        context.read<_Bloc>().add(const _DeleteSelectedItems());
        break;
      default:
        _log.shout("[_onSelectionMenuSelected] Unknown option: $option");
        break;
    }
  }

  Future<void> _onSelectionSharePressed(BuildContext context) async {
    final bloc = context.read<_Bloc>();
    final selected = bloc.state.selectedItems
        .whereType<_FileItem>()
        .map((e) => e.file)
        .toList();
    if (selected.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().shareSelectedEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }
    final result = await showDialog(
      context: context,
      builder: (context) => FileSharer(
        account: bloc.account,
        files: selected,
      ),
    );
    if (result ?? false) {
      bloc.add(const _SetSelectedItems(items: {}));
    }
  }

  Future<void> _onSelectionAddPressed(BuildContext context) async {
    final collection = await Navigator.of(context)
        .pushNamed<Collection>(CollectionPicker.routeName);
    if (collection == null) {
      return;
    }
    context.read<_Bloc>().add(_AddSelectedItemsToCollection(collection));
  }
}

class _EditAppBar extends StatelessWidget {
  const _EditAppBar();

  @override
  Widget build(BuildContext context) {
    final capabilities = context.read<_Bloc>().state.collection.capabilities;
    return SliverAppBar(
      floating: true,
      expandedHeight: 160,
      flexibleSpace: FlexibleSpaceBar(
        background: const _AppBarCover(),
        title: TextFormField(
          initialValue: context.read<_Bloc>().state.currentEditName,
          decoration: InputDecoration(
            hintText: L10n.global().nameInputHint,
          ),
          validator: (_) {
            // use text in state here because the value might be wrong if user
            // scrolled the app bar off screen
            if (context.read<_Bloc>().state.currentEditName.isNotEmpty) {
              return null;
            } else {
              return L10n.global().albumNameInputInvalidEmpty;
            }
          },
          onChanged: (value) {
            context.read<_Bloc>().add(_EditName(value));
          },
          style: TextStyle(
            color: Theme.of(context).appBarTheme.foregroundColor,
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.check),
        color: Theme.of(context).colorScheme.primary,
        tooltip: L10n.global().doneButtonTooltip,
        onPressed: () {
          context.read<_Bloc>().add(const _DoneEdit());
        },
      ),
      actions: [
        if (capabilities.contains(CollectionCapability.labelItem))
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: L10n.global().albumAddTextTooltip,
            onPressed: () => _onAddTextPressed(context),
          ),
        if (capabilities.contains(CollectionCapability.sort))
          IconButton(
            icon: const Icon(Icons.sort_by_alpha),
            tooltip: L10n.global().sortTooltip,
            onPressed: () => _onSortPressed(context),
          ),
      ],
    );
  }

  Future<void> _onAddTextPressed(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleInputDialog(
        buttonText: MaterialLocalizations.of(context).saveButtonLabel,
      ),
    );
    if (result == null) {
      return;
    }
    context.read<_Bloc>().add(_AddLabelToCollection(result));
  }

  Future<void> _onSortPressed(BuildContext context) async {
    final current = context
        .read<_Bloc>()
        .state
        .run((s) => s.editSort ?? s.collection.itemSort);
    final result = await showDialog<CollectionItemSort>(
      context: context,
      builder: (context) => FancyOptionPicker(
        title: L10n.global().sortOptionDialogTitle,
        items: [
          _SortDialogParams(
            L10n.global().sortOptionTimeDescendingLabel,
            CollectionItemSort.dateDescending,
          ),
          _SortDialogParams(
            L10n.global().sortOptionTimeAscendingLabel,
            CollectionItemSort.dateAscending,
          ),
          _SortDialogParams(
            L10n.global().sortOptionFilenameAscendingLabel,
            CollectionItemSort.nameAscending,
          ),
          _SortDialogParams(
            L10n.global().sortOptionFilenameDescendingLabel,
            CollectionItemSort.nameDescending,
          ),
          if (current == CollectionItemSort.manual)
            _SortDialogParams(
              L10n.global().sortOptionManualLabel,
              CollectionItemSort.manual,
            ),
        ]
            .map((e) => FancyOptionPickerItem(
                  label: e.label,
                  isSelected: current == e.value,
                  onSelect: () {
                    Navigator.of(context).pop(e.value);
                  },
                ))
            .toList(),
      ),
    );
    if (result == null) {
      return;
    }
    context.read<_Bloc>().add(_EditSort(result));
  }
}

enum _MenuOption {
  edit,
  download,
}

enum _SelectionMenuOption {
  download,
  removeFromAlbum,
  archive,
  delete,
}

class _SortDialogParams {
  const _SortDialogParams(this.label, this.value);

  final String label;
  final CollectionItemSort value;
}
