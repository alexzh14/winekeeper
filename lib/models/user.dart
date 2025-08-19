import 'dart:convert';


enum UserRole { admin, staff }


class User {
final String id; // uuid-like строка
final String username;
final String password; // MVP: хранится как есть (можно через base64Encode для вида)
final UserRole role;


const User({
required this.id,
required this.username,
required this.password,
required this.role,
});


factory User.fromMap(Map<String, dynamic> map) => User(
id: map['id'] as String,
username: map['username'] as String,
password: map['password'] as String,
role: UserRole.values.firstWhere((e) => e.name == map['role']),
);


Map<String, dynamic> toMap() => {
'id': id,
'username': username,
'password': password,
'role': role.name,
};


static String encodeList(List<User> users) => jsonEncode(users.map((u) => u.toMap()).toList());
static List<User> decodeList(String source) =>
(jsonDecode(source) as List).map((e) => User.fromMap(e as Map<String, dynamic>)).toList();
}