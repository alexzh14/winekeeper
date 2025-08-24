import 'package:flutter/material.dart';

class AppTheme {
  // Основная цветовая палитра (новая мягкая схема)
static const Color _primary = Color(0xFFFF857A);        // Coral
static const Color _primaryLight = Color(0xFFE26C64);   // Hover Coral
static const Color _secondary = Color(0xFFFFD6D1);     // Pastel Pink
static const Color _tertiary = Color(0xFF9EB89C);      // Light Olive

// Фоновые цвета
static const Color _surface = Color(0xFFFAF5EF);       // Ivory (основной фон)
static const Color _background = Color(0xFFFAF5EF);    // Ivory (фон приложения)

// Текстовые цвета
static const Color _onSurface = Color(0xFF362C2A);     // Dark Chocolate
static const Color _onSurfaceVariant = Color(0xFFA3A3A3); // Medium Gray

// Контурные цвета
static const Color _outline = Color(0xFFE6E6E6);       // Light Gray
// Служебные цвета для состояний
static const Color success = Color(0xFF7DBE7F);     // Success
static const Color warning = Color(0xFFFFC072);     // Warning
static const Color error = Color(0xFFE64C4C);       // Error
static const Color hoverOlive = Color(0xFF7FA682);  // Hover Olive

// Вспомогательные серые
static const Color lightGray = Color(0xFFE6E6E6);   // Light Gray
static const Color mediumGray = Color(0xFFA3A3A3);  // Medium Gray

  static ThemeData light() {
    return ThemeData(
      // Включаем Material Design 3
      useMaterial3: true,
      
      // Основная цветовая схема
      colorScheme: ColorScheme.fromSeed(
        seedColor: _primary,
        brightness: Brightness.light,
        primary: _primary,
        secondary: _secondary,
        tertiary: _tertiary,
        surface: _surface,
        onSurface: _onSurface,
        onSurfaceVariant: _onSurfaceVariant,
        outline: _outline,
      ),
      
      // Фон приложения
      scaffoldBackgroundColor: _background,
      
      // Стили для AppBar
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: _surface,
        foregroundColor: _onSurface,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: _onSurface,
        ),
      ),

      // Стили для карточек
      cardTheme: CardThemeData(
        elevation: 0,
        color: _surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Стили для полей ввода
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),

      // Стили для кнопок
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Стили для FloatingActionButton
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),

      // Стили для SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _onSurface,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Стили для переключателей (Switch)
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary; // Активный цвет
          }
          return Colors.grey.shade400; // Неактивный цвет
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _primary.withOpacity(0.5); // Активный трек
          }
          return Colors.grey.shade300; // Неактивный трек
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return _primary.withOpacity(0.1);
          }
          return null;
        }),
      ),
    );
  }

  // Специальные цвета для вин
  static const Color wineRed = Color(0xFFE57373);      // Мягкий красный
  static const Color wineWhite = Color(0xFFFFC072);    // Желтоватый
  static const Color wineRose = Color(0xFFF06292);     // Розовый
  static const Color wineOrange = Color.fromARGB(255, 211, 127, 1);   // Персиковый

  // Вспомогательный метод для получения цвета вина
  static Color getWineColor(String? color) {
    switch (color?.toLowerCase()) {
      case 'красное':
        return wineRed;
      case 'белое':
        return wineWhite;
      case 'розовое':
        return wineRose;
      case 'оранжевое':
        return wineOrange;
      default:
        return _onSurfaceVariant;
    }
  }

  // Готовые тени для карточек
  static BoxShadow get softShadow => BoxShadow(
    color: _outline.withOpacity(0.1),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
}

// Файл app_theme.dart - это центральная "палитра художника" для всего приложения. Изменив несколько строк в нем, вы поменяете дизайн всего приложения.
// 🎯 Что можно менять одним изменением:
// Основные цвета:
// dartstatic const Color _primary = Color(0xFFFF8A65);  // Основной цвет
// static const Color _secondary = Color(0xFFFFCC80); // Вторичный цвет
// Изменив эти две строки - поменяются кнопки, акценты, иконки по всему приложению.
// Цвета вин:
// dartstatic const Color wineRed = Color(0xFFE57373);
// static const Color wineWhite = Color(0xFFFFF176);
// Поменяв эти строки - изменятся цвета индикаторов вин во всех карточках.
// Скругления:
// dartBorderRadius.circular(16) // Поменяв 16 на 8 или 24
// Сделает все элементы менее или более округлыми.
// 🚀 Преимущества такого подхода:
// ✅ Одно место для всех изменений - не нужно искать по 10 файлам
// ✅ Консистентность - все элементы автоматически в одном стиле
// ✅ Быстрые эксперименты - поменял пару цветов, перезапустил, посмотрел
// ✅ Темная тема - можно легко добавить AppTheme.dark()
// 💡 Например, для смены на зеленую палитру:
// dartstatic const Color _primary = Color(0xFF4CAF50);    // Зеленый
// static const Color _secondary = Color(0xFF8BC34A);  // Салатовый
// И все приложение станет зеленым!