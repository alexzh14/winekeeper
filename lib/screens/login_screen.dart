import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:winekeeper/core/app_theme.dart';
import 'package:winekeeper/widgets/main_navigation.dart';

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

      // переход на MainNavigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigation()),
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
    // Получаем размеры экрана для адаптивности
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Адаптивный размер логотипа (30% высоты экрана, но не больше 200px)
    final logoSize = (screenHeight * 0.25).clamp(120.0, 200.0);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Гибкий отступ сверху
                  const Flexible(child: SizedBox(height: 40)),

                  // Адаптивный логотип с изображением
                  Container(
                    width: logoSize,
                    height: logoSize,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface, // фон Ivory
                      borderRadius: BorderRadius.circular(logoSize / 5), // пропорциональное скругление
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(logoSize / 8), // пропорциональные отступы
                      child: Image.asset(
                        'assets/images/logo.png', // ваш оригинальный путь к логотипу
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Заголовок
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

                  // Поля ввода в контейнере с ограниченной шириной
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: (screenWidth * 0.9).clamp(280.0, 400.0),
                    ),
                    child: Column(
                      children: [
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

                  // Гибкий отступ снизу
                  const Flexible(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}