import 'package:flutter/widgets.dart';

class NavigationManager {
  factory NavigationManager() => _inst;

  NavigationManager._();

  void setHandler(NavigationHandler handler) {
    _handler = handler;
  }

  void unsetHandler(NavigationHandler handler) {
    _handler = null;
  }

  NavigatorState? getNavigator() => _handler?.getNavigator();

  NavigationHandler? _handler;

  static final _inst = NavigationManager._();
}

abstract class NavigationHandler {
  NavigatorState? getNavigator();
}
