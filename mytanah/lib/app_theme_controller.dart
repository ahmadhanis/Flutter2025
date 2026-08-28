import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> appThemeMode = ValueNotifier(ThemeMode.light);

bool get isAppDarkMode => appThemeMode.value == ThemeMode.dark;

const String _themeModeKey = 'theme_mode';

Future<void> loadAppThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString(_themeModeKey);
  appThemeMode.value = savedMode == ThemeMode.dark.name
      ? ThemeMode.dark
      : ThemeMode.light;
}

Future<void> setAppThemeMode(ThemeMode mode) async {
  appThemeMode.value = mode;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themeModeKey, mode.name);
}

Future<void> setAppDarkMode(bool value) {
  return setAppThemeMode(value ? ThemeMode.dark : ThemeMode.light);
}
