import 'package:flutter/material.dart';


class AppTheme {
static ThemeData light() {
// Спокойная палитра: мягкие серые, голубые акценты
const primary = Color(0xFF4A90E2); // спокойный голубой
const surface = Color(0xFFF7F9FC);


return ThemeData(
useMaterial3: true,
colorScheme: ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light),
scaffoldBackgroundColor: surface,
inputDecorationTheme: const InputDecorationTheme(
border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
focusedBorder: OutlineInputBorder(
borderRadius: BorderRadius.all(Radius.circular(14)),
borderSide: BorderSide(width: 1.6),
),
contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
),
cardTheme: CardTheme(
elevation: 0,
color: Colors.white,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
),
appBarTheme: const AppBarTheme(centerTitle: true),
elevatedButtonTheme: ElevatedButtonThemeData(
style: ElevatedButton.styleFrom(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
),
),
);
}
}