import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';


class UserRepository {
static const _kUsersKey = 'users_v1';


Future<List<User>> getAll() async {
final prefs = await SharedPreferences.getInstance();
final raw = prefs.getString(_kUsersKey);
if (raw == null || raw.isEmpty) return [];
return User.decodeList(raw);
}


Future<void> saveAll(List<User> users) async {
final prefs = await SharedPreferences.getInstance();
await prefs.setString(_kUsersKey, User.encodeList(users));
}


Future<void> seedIfEmpty() async {
final current = await getAll();
if (current.isNotEmpty) return;
// Первый запуск: создаём администратора по умолчанию
final admin = User(
id: _genId(),
username: 'admin',
password: base64Encode(utf8.encode('admin123')), // лёгкая маскировка
role: UserRole.admin,
);
await saveAll([admin]);
}


Future<void> add(User user) async {
final all = await getAll();
all.add(user);
await saveAll(all);
}


Future<void> remove(String id) async {
final all = await getAll();
all.removeWhere((u) => u.id == id);
await saveAll(all);
}


Future<User?> findByUsername(String username) async {
final all = await getAll();
try {
return all.firstWhere((u) => u.username.toLowerCase() == username.toLowerCase());
} catch (_) {
return null;
}
}
}


String _genId() {
// Простая генерация id (MVP). Для продакшена — пакет uuid
final millis = DateTime.now().millisecondsSinceEpoch;
return 'u_$millis';
}