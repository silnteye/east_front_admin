import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

enum AppThemeType { light, dark, teal, sunset }

extension AppThemeTypeExtension on AppThemeType {
  String get name {
    switch (this) {
      case AppThemeType.light: return "Light Theme";
      case AppThemeType.dark: return "Dark Theme";
      case AppThemeType.teal: return "Classic Teal";
      case AppThemeType.sunset: return "Sunset Amber";
    }
  }

  ThemeData getThemeData() {
    switch (this) {
      case AppThemeType.light:
        return ThemeData.light(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            primary: const Color(0xFF6C63FF),
            surface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xF2F4F5F9),
          cardColor: Colors.white,
          dividerColor: const Color(0xFFE2E2EC),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            titleTextStyle: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: Color(0xFF2C2C3E), fontSize: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A2E),
            elevation: 0,
            iconTheme: IconThemeData(color: Color(0xFF1A1A2E)),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFECECF4),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 1.5)),
            labelStyle: const TextStyle(color: Color(0xFF5A5A75)),
            hintStyle: const TextStyle(color: Color(0xFF9090A8)),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFECECF4),
            selectedColor: const Color(0xFF6C63FF),
            disabledColor: Colors.grey[200],
            labelStyle: const TextStyle(color: Color(0xFF1A1A2E)),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textTheme: ThemeData.light().textTheme.apply(fontFamily: "Inter", bodyColor: Colors.black, displayColor: Colors.black),
        );
      case AppThemeType.dark:
        return ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6C63FF),
            brightness: Brightness.dark,
            primary: const Color(0xFF8B80FF),
            surface: const Color(0xFF16162D),
          ),
          scaffoldBackgroundColor: const Color(0xF20E0E1F),
          cardColor: const Color(0xFF16162D),
          dividerColor: const Color(0xFF24243E),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF16162D),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            contentTextStyle: const TextStyle(color: Colors.white70, fontSize: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF16162D),
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF16162D),
            foregroundColor: Colors.white,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.white),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF20203D),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF8B80FF), width: 1.5)),
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white30),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF20203D),
            selectedColor: const Color(0xFF8B80FF),
            disabledColor: Colors.grey[800],
            labelStyle: const TextStyle(color: Colors.white70),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: "Inter", bodyColor: Colors.white, displayColor: Colors.white),
        );
      case AppThemeType.teal:
        return ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.dark,
            primary: Colors.tealAccent,
            surface: const Color(0xFF10272B),
          ),
          scaffoldBackgroundColor: const Color(0xF209171A),
          cardColor: const Color(0xFF10272B),
          dividerColor: const Color(0xFF183B40),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF10272B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF10272B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF10272B),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF153338),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.tealAccent, width: 1.5)),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF153338),
            selectedColor: Colors.teal,
            disabledColor: Colors.grey[800],
            labelStyle: const TextStyle(color: Colors.white70),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: "Inter", bodyColor: Colors.white, displayColor: Colors.white),
        );
      case AppThemeType.sunset:
        return ThemeData.dark(useMaterial3: true).copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
            brightness: Brightness.dark,
            primary: Colors.orangeAccent,
            surface: const Color(0xFF2D1812),
          ),
          scaffoldBackgroundColor: const Color(0xF21D0E09),
          cardColor: const Color(0xFF2D1812),
          dividerColor: const Color(0xFF3F221A),
          dialogTheme: DialogThemeData(
            backgroundColor: const Color(0xFF2D1812),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF2D1812),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2D1812),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF381F17),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5)),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFF381F17),
            selectedColor: Colors.deepOrange,
            disabledColor: Colors.grey[800],
            labelStyle: const TextStyle(color: Colors.white70),
            secondaryLabelStyle: const TextStyle(color: Colors.white),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: "Inter", bodyColor: Colors.white, displayColor: Colors.white),
        );
    }
  }
}

class AppThemeNotifier extends Notifier<AppThemeType> {
  @override
  AppThemeType build() {
    _load();
    return AppThemeType.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt("selected_app_theme") ?? 0;
    if (index >= 0 && index < AppThemeType.values.length) {
      state = AppThemeType.values[index];
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("selected_app_theme", type.index);
  }
}

final appThemeProvider = NotifierProvider<AppThemeNotifier, AppThemeType>(AppThemeNotifier.new);
