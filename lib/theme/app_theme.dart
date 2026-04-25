import 'package:flutter/material.dart';

class AppThemes {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0XFF0F1117),
    canvasColor: const Color(0xFF1A2035),
    cardColor: const Color(0xFF1A2035),
    primaryColor: const Color(0xFF578ADD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0XFF0F1117),
      foregroundColor: Color(0xFFF9FAFB),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Color(0xFFF9FAFB)),
    ),
  );
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF3F4F6),
    canvasColor: Colors.white,
    cardColor: Colors.white,
    primaryColor: const Color(0xFF578ADD),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF3F4F6),
      foregroundColor: Colors.black87,
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black54),
    ),
  );
}
