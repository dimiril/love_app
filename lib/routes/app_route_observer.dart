import 'package:flutter/material.dart';

class AppRouteObserver extends NavigatorObserver {
  static final List<Route> activeStack = [];

  static List<String> get activeNames =>
      activeStack.map((e) => e.settings.name ?? '').toList();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.add(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.remove(route);
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    activeStack.remove(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) activeStack.remove(oldRoute);
    if (newRoute != null) activeStack.add(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}