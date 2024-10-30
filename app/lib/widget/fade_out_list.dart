import 'dart:async';

import 'package:flutter/material.dart';

class FadeOutListContainer extends StatefulWidget {
  const FadeOutListContainer({
    super.key,
    required this.scrollController,
    required this.child,
  });

  @override
  State<StatefulWidget> createState() => _FadeOutListContainerState();

  final ScrollController scrollController;
  final Widget child;
}

class _FadeOutListContainerState extends State<FadeOutListContainer> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScrollEvent);
    _ensureUpdateButtonScroll();
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScrollEvent);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
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
      child: widget.child,
    );
  }

  void _onScrollEvent() {
    _updateButtonScroll(widget.scrollController.position);
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
    if (widget.scrollController.hasClients) {
      if (_updateButtonScroll(widget.scrollController.position)) {
        return;
      }
    }
    Timer(const Duration(milliseconds: 100), _ensureUpdateButtonScroll);
  }

  var _hasFirstScrollUpdate = false;
  var _hasLeftContent = false;
  var _hasRightContent = false;
}
