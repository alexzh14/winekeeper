import 'package:flutter/material.dart';
import 'package:winekeeper/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winekeeper/core/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Введите email и пароль")),
      );
      return;
    }

    // фиксированные значения для входа
    const validEmail = "admin@winekeeper.com";
    const validPassword = "1234567";

    if (email == validEmail && password == validPassword) {
      // сохраняем статус входа
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      // переход на HomeScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // если данные не совпали — ошибка
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Неверный email или пароль")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 480, // Увеличено в 4 раза
                height: 480, // Увеличено в 4 раза
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface, // фон Ivory
                  borderRadius:
                      BorderRadius.circular(96), // Пропорционально увеличено
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.2), // более мягкая тень
                      blurRadius: 64, // Пропорционально увеличено
                      offset: const Offset(0, 32), // Пропорционально увеличено
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.all(64), // Пропорционально увеличено
                  child: Image.asset(
                    'assets/images/logo.png', // путь к вашему логотипу
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "WineKeeper",
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Управление винотекой",
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 40),

              // Поле Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),

              // Поле Пароль
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Пароль",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),

              // Кнопка входа
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Войти",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
