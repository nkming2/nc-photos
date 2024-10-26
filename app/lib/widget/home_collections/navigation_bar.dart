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
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ShaderMask(
              shaderCallback: (rect) {
                final colors = <Color>[];
                final stops = <double>[];
                if (_hasLeftContent) {
                  colors.addAll([Colors.white, Colors.transparent]);
                  stops.addAll([0, .1]);
                } else {
                  colors.add(Colors.transparent);
                  stops.add(0);
                }
                if (_hasRightContent) {
                  colors.addAll([Colors.transparent, Colors.white]);
                  stops.addAll([.9, 1]);
                } else {
                  colors.add(Colors.transparent);
                  stops.add(1);
                }
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                  stops: stops,
                ).createShader(rect);
              },
              blendMode: BlendMode.dstOut,
              child: _BlocSelector(
                selector: (state) => state.navBarButtons,
                builder: (context, navBarButtons) {
                  final buttons = navBarButtons
                      .map((e) => _buildButton(context, e))
                      .nonNulls
                      .toList();
                  return ListView.separated(
                    controller: _scrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: buttons.length,
                    itemBuilder: (context, i) => Center(
                      child: buttons[i],
                    ),
                    separatorBuilder: (context, _) => const SizedBox(width: 12),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _NavBarNewButton(),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget? _buildButton(BuildContext context, PrefHomeCollectionsNavButton btn) {
    switch (btn.type) {
      case HomeCollectionsNavBarButtonType.sharing:
        return _NavBarSharingButton(isMinimized: btn.isMinimized);
      case HomeCollectionsNavBarButtonType.edited:
        return features.isSupportEnhancement
            ? _NavBarEditedButton(isMinimized: btn.isMinimized)
            : null;
      case HomeCollectionsNavBarButtonType.archive:
        return _NavBarArchiveButton(isMinimized: btn.isMinimized);
      case HomeCollectionsNavBarButtonType.trash:
        return _NavBarTrashButton(isMinimized: btn.isMinimized);
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
