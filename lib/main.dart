import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winekeeper/screens/login_screen.dart';
import 'package:winekeeper/screens/home_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_card.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/models/sale_record.dart';
import 'package:winekeeper/models/audit_session.dart';  // ДОБАВЛЕНО
import 'package:winekeeper/core/app_theme.dart';
import 'package:winekeeper/widgets/main_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Регистрируем адаптеры для всех моделей
  Hive.registerAdapter(WineCardAdapter());     // typeId: 0
  Hive.registerAdapter(WineBottleAdapter());   // typeId: 1  
  Hive.registerAdapter(SaleRecordAdapter());   // typeId: 2
  Hive.registerAdapter(AuditSessionAdapter()); // typeId: 3  // ДОБАВЛЕНО

  // Открываем боксы для хранения данных
  await Hive.openBox<WineCard>('wine_cards');
  await Hive.openBox<WineBottle>('wine_bottles');
  await Hive.openBox<SaleRecord>('sale_records');
  await Hive.openBox<AuditSession>('audit_sessions');  // ДОБАВЛЕНО

  // Проверяем версию данных и очищаем при необходимости
  await _checkAndMigrateData();

  // SharedPreferences для авторизации
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(WineKeeperApp(isLoggedIn: isLoggedIn));
}

/// Проверка версии данных и миграция при необходимости
Future<void> _checkAndMigrateData() async {
  const currentDataVersion = 3; // Увеличили версию для новой модели
  
  final prefs = await SharedPreferences.getInstance();
  final storedVersion = prefs.getInt('data_version') ?? 0;
  
  if (storedVersion < currentDataVersion) {
    print('🔄 Обнаружены изменения в моделях данных. Очищаем старые данные...');
    
    // Очищаем все боксы с данными
    await Hive.box<WineCard>('wine_cards').clear();
    await Hive.box<WineBottle>('wine_bottles').clear();
    await Hive.box<SaleRecord>('sale_records').clear();
    await Hive.box<AuditSession>('audit_sessions').clear();  // ДОБАВЛЕНО
    
    // Обновляем версию
    await prefs.setInt('data_version', currentDataVersion);
    
    print('✅ Данные очищены. Можно добавлять новые записи.');
  }
}

class WineKeeperApp extends StatelessWidget {
  final bool isLoggedIn;

  const WineKeeperApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WineKeeper',
      theme: AppTheme.light(),
      // Убираем прямую навигацию к HomeScreen - всегда через MainNavigation
      home: isLoggedIn ? const MainNavigation() : const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainNavigation(),
      },
    );
  }
}