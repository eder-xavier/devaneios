import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeManager extends InheritedWidget {
  final ValueNotifier<bool> isAyahuascaEnabled;
  final ValueNotifier<String> backgroundImage;

  ThemeManager({super.key, required super.child})
    : isAyahuascaEnabled = ValueNotifier<bool>(false),
      backgroundImage = ValueNotifier<String>('forest_background') {
    _loadAyahuascaState();
  }

  static ThemeManager of(BuildContext context) {
    final ThemeManager? result = context
        .dependOnInheritedWidgetOfExactType<ThemeManager>();
    assert(result != null, 'No ThemeManager found in context');
    return result!;
  }

  Future<void> _loadAyahuascaState() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('isAyahuascaEnabled') ?? false;
    isAyahuascaEnabled.value = isEnabled;
    backgroundImage.value = isEnabled
        ? 'forest_background2'
        : 'forest_background';
  }

  Future<void> toggleAyahuasca(bool value) async {
    isAyahuascaEnabled.value = value;
    backgroundImage.value = value ? 'forest_background2' : 'forest_background';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isAyahuascaEnabled', value);
  }

  @override
  bool updateShouldNotify(ThemeManager oldWidget) {
    return isAyahuascaEnabled != oldWidget.isAyahuascaEnabled ||
        backgroundImage != oldWidget.backgroundImage;
  }
}
