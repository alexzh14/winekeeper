import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winekeeper/screens/login_screen.dart';
import 'package:winekeeper/screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}

