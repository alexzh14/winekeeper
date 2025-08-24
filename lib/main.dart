import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winekeeper/screens/login_screen.dart';
import 'package:winekeeper/screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрируем адаптер для модели WineBottle
  Hive.registerAdapter(WineBottleAdapter());

  // Открываем коробку (box) для хранения вин
  await Hive.openBox<WineBottle>('wine_bottles');

  // SharedPreferences для авторизации
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(WineKeeperApp(isLoggedIn: isLoggedIn));
}

class WineKeeperApp extends StatelessWidget {
  final bool isLoggedIn;

  const WineKeeperApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WineKeeper',
      theme: AppTheme.light(), // вместо старой темы
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
