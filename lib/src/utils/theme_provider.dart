import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'app_theme.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeNotifier extends _$ThemeNotifier {
  @override
  AppThemeType build() {
    return AppThemeType.dark;
  }

  void setTheme(AppThemeType type) {
    state = type;
  }
}
