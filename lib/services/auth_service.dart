import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import 'user_repository.dart';


class AuthService {
final UserRepository _repo;
final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);


AuthService(this._repo);


Future<void> init() async {
await _repo.seedIfEmpty();
}


Future<bool> login(String username, String password) async {
final user = await _repo.findByUsername(username);
if (user == null) return false;


// MVP: пароли «сравниваем» через base64 для видимости
final encoded = base64Encode(utf8.encode(password));
if (user.password == encoded) {
currentUser.value = user;
return true;
}
return false;
}


void logout() {
currentUser.value = null;
}


Future<bool> isAdmin() async {
final u = currentUser.value;
return u?.role == UserRole.admin;
}


Future<User> createUser({
required String username,
required String password,
required UserRole role,
}) async {
final existing = await _repo.findByUsername(username);
if (existing != null) {
throw Exception('Пользователь с таким логином уже существует');
}
final user = User(
id: _genId(),
username: username,
password: base64Encode(utf8.encode(password)),
role: role,
);
await _repo.add(user);
return user;
}
}


String _genId() {
final millis = DateTime.now().millisecondsSinceEpoch;
return 'u_$millis';
}