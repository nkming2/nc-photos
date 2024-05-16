part of '../home_photos2.dart';

class _ContentList extends StatelessWidget {
  const _ContentList();

  @override
  Widget build(BuildContext context) {
    return _BlocSelector<int>(
      selector: (state) => state.zoom,
      builder: (context, zoom) => _ContentListBody(
        maxCrossAxisExtent: photo_list_util.getThumbSize(zoom).toDouble(),
        isNeedVisibilityInfo: true,
      ),
    );
  }
}

class _ScalingList extends StatelessWidget {
  const _ScalingList();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) => previous.scale != current.scale,
      builder: (context, state) {
        if (state.scale == null) {
          return const SizedBox.shrink();
        }
        int nextZoom;
        if (state.scale! > 1) {
          nextZoom = state.zoom + 1;
        } else {
          nextZoom = state.zoom - 1;
        }
        nextZoom = nextZoom.clamp(-1, 2);
        return _ContentListBody(
          maxCrossAxisExtent: photo_list_util.getThumbSize(nextZoom).toDouble(),
          isNeedVisibilityInfo: false,
        );
      },
    );
  }
}

@npLog
class _ContentListBody extends StatelessWidget {
  const _ContentListBody({
    required this.maxCrossAxisExtent,
    required this.isNeedVisibilityInfo,
  });

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.transformedItems != current.transformedItems ||
          previous.selectedItems != current.selectedItems,
      builder: (context, state) => SelectableItemList<_Item>(
        maxCrossAxisExtent: maxCrossAxisExtent,
        items: state.transformedItems,
        itemBuilder: (context, index, item) {
          final w = item.buildWidget(context);
          if (isNeedVisibilityInfo) {
            return _ContentListItemView(
              key: Key("${_log.fullName}.${item.id}"),
              item: item,
              child: w,
            );
          } else {
            return w;
          }
        },
        staggeredTileBuilder: (_, item) => item.staggeredTile,
        selectedItems: state.selectedItems,
        onSelectionChange: (_, selected) {
          context.addEvent(_SetSelectedItems(items: selected.cast()));
        },
        onItemTap: (context, index, _) {
          if (state.transformedItems[index] is! _FileItem) {
            return;
          }
          final actualIndex = index -
              state.transformedItems
                  .sublist(0, index)
                  .where((e) => e is! _FileItem)
                  .length;
          Navigator.of(context).pushNamed(
            Viewer.routeName,
            arguments: ViewerArguments(
              context.bloc.account,
              state.transformedItems
                  .whereType<_FileItem>()
                  .map((e) => e.file)
                  .toList(),
              actualIndex,
            ),
          );
        },
        onMaxExtentChange: (value) {
          context.addEvent(_SetContentListMaxExtent(value));
        },
      ),
    );
  }

  final double maxCrossAxisExtent;
  final bool isNeedVisibilityInfo;
}

class _ContentListItemView extends StatefulWidget {
  const _ContentListItemView({
    required super.key,
    required this.item,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _ContentListItemViewState();

  final _Item item;
  final Widget child;
}

class _ContentListItemViewState extends State<_ContentListItemView> {
  @override
  void initState() {
    super.initState();
    bloc = context.bloc;
  }

  @override
  void dispose() {
    final date = _getDate();
    if (date != null) {
      bloc.add(_RemoveVisibleDate(_VisibleDate(widget.item.id, date)));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key("${widget.key}.detector"),
      onVisibilityChanged: (info) {
        if (context.mounted) {
          final date = _getDate();
          if (date != null) {
            if (info.visibleFraction >= 0.2) {
              context.addEvent(
                  _AddVisibleDate(_VisibleDate(widget.item.id, date)));
            } else {
              context.addEvent(
                  _RemoveVisibleDate(_VisibleDate(widget.item.id, date)));
            }
          }
        }
      },
      child: widget.child,
    );
  }

  Date? _getDate() {
    final item = widget.item;
    Date? date;
    if (item is _FileItem) {
      date = item.file.fdDateTime.toLocal().toDate();
    } else if (item is _SummaryFileItem) {
      date = item.date;
    }
    return date;
  }

  late final _Bloc bloc;
}

class _MemoryCollectionList extends StatelessWidget {
  const _MemoryCollectionList();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: _MemoryCollectionItem.height,
        child: _BlocSelector<List<Collection>>(
          selector: (state) => state.memoryCollections,
          builder: (context, memoryCollections) => ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: memoryCollections.length,
            itemBuilder: (context, index) {
              final c = memoryCollections[index];
              return _MemoryCollectionItemView(
                coverUrl: c.getCoverUrl(
                  k.photoThumbSize,
                  k.photoThumbSize,
                  isKeepAspectRatio: true,
                ),
                label: c.name,
                onTap: () {
                  Navigator.of(context).pushNamed(
                    CollectionBrowser.routeName,
                    arguments: CollectionBrowserArguments(c),
                  );
                },
              );
            },
            separatorBuilder: (context, index) => const SizedBox(width: 8),
          ),
        ),
      ),
    );
  }
}

class _MemoryCollectionItemView extends StatelessWidget {
  static const width = 96.0;
  static const height = width * 1.15;

  const _MemoryCollectionItemView({
    required this.coverUrl,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PhotoListImage(
                account: context.bloc.account,
                previewUrl: coverUrl,
                padding: const EdgeInsets.all(0),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: AlignmentDirectional.bottomStart,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            color: Theme.of(context).onDarkSurface,
                          ),
                    ),
                  ),
                ),
              ),
              if (onTap != null)
                Positioned.fill(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: onTap,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  final String? coverUrl;
  final String label;
  final VoidCallback? onTap;
}

class _ScrollLabel extends StatelessWidget {
  const _ScrollLabel();

  @override
  Widget build(BuildContext context) {
    return _BlocSelector<Date?>(
      selector: (state) => state.scrollDate,
      builder: (context, scrollDate) {
        if (scrollDate == null) {
          return const SizedBox.shrink();
        }
        final text = DateFormat(DateFormat.YEAR_ABBR_MONTH,
                Localizations.localeOf(context).languageCode)
            .format(scrollDate.toUtcDateTime());
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: Theme.of(context).colorScheme.onSecondaryContainer),
            child: Text(text),
          ),
        );
      },
    );
  }
}
