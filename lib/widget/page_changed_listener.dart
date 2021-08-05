import 'package:flutter/widgets.dart';

class PageChangedListener {
  PageChangedListener(
    this.pageController, {
    this.onPageChanged,
  }) : _prevPage = pageController.initialPage;

  void call() {
    if (pageController.hasClients) {
      final page = pageController.page!.round();
      if (page != _prevPage) {
        onPageChanged?.call(page);
        _prevPage = page;
      }
    }
  }

  final PageController pageController;
  final ValueChanged<int>? onPageChanged;
  int _prevPage;
}
