import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  static const green = Color(0xFF00C52B);
  static const deepGreen = Color(0xFF009E24);
  static const paleGreen = Color(0xFFE9FBEF);
  static const ink = Color(0xFF151715);
  static const muted = Color(0xFF777D78);
  static const canvas = Color(0xFFF4F7F4);
  static const line = Color(0xFFE7EBE7);
  static const danger = Color(0xFFE53935);
  static const amber = Color(0xFFFFA000);
}

class AppAssets {
  static const logo = 'assets/images/shoe_factory_logo.png';
}

class AppDecor {
  static const shadow = [
    BoxShadow(
      color: Color(0x14151715),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static BoxDecoration card({double radius = 18, Color color = Colors.white}) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadow,
    );
  }

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1AD143), Color(0xFF009E24)],
  );

  static BoxDecoration header = BoxDecoration(
    gradient: headerGradient,
    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
    boxShadow: [
      BoxShadow(
        color: AppColors.deepGreen.withValues(alpha: 0.28),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class AppTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      surface: Colors.white,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      splashColor: AppColors.paleGreen,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.green),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
            color: AppColors.ink, fontSize: 18, fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(color: AppColors.ink),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.ink),
        titleLarge: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
        titleMedium: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        bodyMedium: TextStyle(fontSize: 14, color: AppColors.ink),
        bodySmall: TextStyle(fontSize: 12, color: AppColors.muted),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.line)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppColors.line)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB7E7C2),
          minimumSize: const Size(48, 50),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepGreen,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: AppColors.green),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepGreen,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: AppColors.paleGreen,
        backgroundColor: Colors.white,
        side: const BorderSide(color: AppColors.line),
        labelStyle:
            const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.paleGreen,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.deepGreen : AppColors.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
              color: selected ? AppColors.deepGreen : AppColors.muted);
        }),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(color: Colors.white),
        actionTextColor: AppColors.green,
      ),
      dividerColor: AppColors.line,
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.green;
          return null;
        }),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.green;
          return AppColors.muted;
        }),
      ),
    );
  }
}

Color shoeColor(String name) {
  switch (name) {
    case 'Green':
      return AppColors.green;
    case 'Black':
      return const Color(0xFF1A1A1A);
    case 'White':
      return const Color(0xFFF4F4F4);
    case 'Red':
      return const Color(0xFFD32F2F);
    case 'Navy':
      return const Color(0xFF1A237E);
    case 'Brown':
      return const Color(0xFF6D4C41);
    case 'Grey':
      return const Color(0xFFB0B6B0);
    case 'Beige':
      return const Color(0xFFE6D3B3);
    default:
      return AppColors.muted;
  }
}
