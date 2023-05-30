import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  NavigationService._internal();

  /// With this factory setup, any time  NavigationService() is called
  /// within the appication _instance will be returned and not a new instance
  factory NavigationService() => _instance;

  ///This would allow the app monitor the current screen state during navigation.
  ///
  ///This is where the singleton setup we did
  ///would help as the state is internally maintained
  static GlobalKey<NavigatorState> navigationKey = GlobalKey<NavigatorState>();
  static Future<dynamic> navigateToScreen(Widget page, {arguments}) async =>
      navigationKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => page,
        ),
      );

  /// This allows you to naviagte to the next screen and
  /// also replace the current screen by passing the screen widget
  static Future<dynamic> replaceScreen(Widget page, {arguments}) async =>
      navigationKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => page,
          ),
          ((route) => false));

  static goBack() {
    navigationKey.currentState!.pop();
  }
}