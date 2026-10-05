import 'package:flutter/material.dart';

class NavigationService {
  factory NavigationService() => _singleton;
  NavigationService._init();
  static final NavigationService _singleton = NavigationService._init();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(
      routeName,
      arguments: arguments,
    );
  }

  Future<T?> push<T>(Route<T> route, {Object? arguments}) {
    return navigatorKey.currentState!.push<T>(route);
  }

  Future<T?> pushNamedAndRemoveAll<T>(String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamedAndRemoveUntil<T>(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  void pop<T>([T? result]) {
    return navigatorKey.currentState!.pop<T>(result);
  }
}