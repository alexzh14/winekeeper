import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:winekeeper/models/wine_bottle.dart';
import 'package:winekeeper/screens/admin_users_screen.dart';
import 'package:winekeeper/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<WineBottle> wineBox;

  @override
  void initState() {
    super.initState();
    wineBox = Hive.box<WineBottle>('wine_bottles');
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Главная"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Выйти",
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          const Text(
            "Добро пожаловать в систему учёта вина!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // список вин
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: wineBox.listenable(),
              builder: (context, Box<WineBottle> box, _) {
                if (box.isEmpty) {
                  return const Center(child: Text("В базе пока нет вин"));
                }

                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final wine = box.getAt(index);
                    if (wine == null) return const SizedBox.shrink();
                    return ListTile(
                      title: Text(wine.name),
                      subtitle: Text(
                        wine.year != null ? wine.year.toString() : "",
                      ),
                      trailing: Text(wine.country ?? ""),
                    );
                  },
                );
              },
            ),
          ),

          // кнопка перехода к пользователям
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // пример: добавляем тестовое вино
          final newWine = WineBottle(
            name: "Cabernet Sauvignon",
            country: "France",
            year: 2018,
            color: "Красное",
            quantity: 1,
          );
          await wineBox.add(newWine);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
