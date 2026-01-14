import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:mosstroinform_mobile/core/utils/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_provider.g.dart';

const String _themeModeKey = 'theme_mode';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    try {
      final settingsBox = Hive.box('settings');
      final savedThemeMode = settingsBox.get(_themeModeKey) as String?;

      if (savedThemeMode != null) {
        switch (savedThemeMode) {
          case 'light':
            return ThemeMode.light;
          case 'dark':
            return ThemeMode.dark;
          case 'system':
            return ThemeMode.system;
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Ошибка получения темы, используется тема по умолчанию', e, stackTrace);
    }

    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    try {
      Box settingsBox;
      if (Hive.isBoxOpen('settings')) {
        settingsBox = Hive.box('settings');
      } else {
        try {
          final appSupportDir = await getApplicationSupportDirectory();
          await Hive.initFlutter(appSupportDir.path);
        } catch (e, stackTrace) {
          AppLogger.error('Ошибка инициализации Hive', e, stackTrace);
        }
        settingsBox = await Hive.openBox('settings');
      }

      String themeModeString;
      switch (mode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
          themeModeString = 'system';
          break;
      }

      await settingsBox.put(_themeModeKey, themeModeString);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        AppLogger.error('Ошибка сохранения темы', e, stackTrace);
      }
    }
  }
}
