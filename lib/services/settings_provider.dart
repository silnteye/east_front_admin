import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeSetting { small, medium, large, extraLarge }

enum AppUrduFont { nastaliq, sans }

class SettingsState {
  final FontSizeSetting fontSize;
  final double lineSpacing;
  final AppUrduFont urduFont;

  const SettingsState({
    this.fontSize = FontSizeSetting.medium,
    this.lineSpacing = 1.5,
    this.urduFont = AppUrduFont.nastaliq,
  });

  SettingsState copyWith({
    FontSizeSetting? fontSize,
    double? lineSpacing,
    AppUrduFont? urduFont,
  }) {
    return SettingsState(
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      urduFont: urduFont ?? this.urduFont,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _load();
    return const SettingsState();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final fsIndex = prefs.getInt('font_size_index') ?? 1;
    final ls = prefs.getDouble('line_spacing') ?? 1.5;
    final ufIndex = prefs.getInt('urdu_font_index') ?? 0;
    state = SettingsState(
      fontSize: FontSizeSetting.values[fsIndex],
      lineSpacing: ls,
      urduFont: AppUrduFont.values[ufIndex],
    );
  }

  Future<void> setFontSize(FontSizeSetting size) async {
    state = state.copyWith(fontSize: size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('font_size_index', size.index);
  }

  Future<void> setLineSpacing(double spacing) async {
    state = state.copyWith(lineSpacing: spacing);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('line_spacing', spacing);
  }

  Future<void> setUrduFont(AppUrduFont font) async {
    state = state.copyWith(urduFont: font);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('urdu_font_index', font.index);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);

extension FontSizeSettingExt on FontSizeSetting {
  double get scaleFactor {
    switch (this) {
      case FontSizeSetting.small: return 0.85;
      case FontSizeSetting.medium: return 1.0;
      case FontSizeSetting.large: return 1.15;
      case FontSizeSetting.extraLarge: return 1.3;
    }
  }

  String get label {
    switch (this) {
      case FontSizeSetting.small: return 'Small';
      case FontSizeSetting.medium: return 'Medium';
      case FontSizeSetting.large: return 'Large';
      case FontSizeSetting.extraLarge: return 'Extra Large';
    }
  }
}
