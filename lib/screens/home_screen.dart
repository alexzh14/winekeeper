import 'package:flutter/material.dart';
import 'package:wine_inventory/screens/admin_users_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Главная")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Добро пожаловать в систему учёта вина!"),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminUsersScreen(),
                  ),
                );
              },
              child: const Text("Перейти к управлению пользователями"),
            ),
          ],
        ),
      ),
    );
  }
}
