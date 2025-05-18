// lib/model/user.dart
import 'package:uuid/uuid.dart';

enum UserRole { client, restaurant }

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? userImagePath; // <<< NOVO: Caminho/URL para foto de perfil

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.userImagePath, // <<< Adicionado ao construtor
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'userImagePath': userImagePath, // <<< Adicionado ao JSON
  };

  factory User.fromJson(Map<String, dynamic> json) {
    UserRole roleFromJson = UserRole.values.firstWhere(
      (e) => e.name == json['role'],
      orElse: () => UserRole.client,
    );
    return User(
      id: json['id'] ?? const Uuid().v4(),
      name: json['name'] ?? 'Utilizador Desconhecido',
      email: json['email'] ?? '',
      role: roleFromJson,
      userImagePath: json['userImagePath'] as String?, // <<< Lido do JSON
    );
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? userImagePath, // <<< Adicionado ao copyWith
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      userImagePath: userImagePath ?? this.userImagePath,
    );
  }

  // --- Overrides para comparação e representação em string ---
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    // Representação textual do objeto para debug
    return 'User(id: $id, name: $name, email: $email, role: ${role.name})';
  }
}
