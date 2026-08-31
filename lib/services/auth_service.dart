import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario_model.dart';

class AuthService {
  static const String _storageKey = 'fideliz_usuario';

  static Future<Usuario?> carregarSessao() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      return null;
    }

    try {
      final decoded = json.decode(jsonString);
      if (decoded is! Map) {
        return null;
      }

      return Usuario.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  static Future<Usuario?> login({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();
    final senhaLimpa = senha.trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailLimpo)) {
      return null;
    }

    if (senhaLimpa.length < 6) {
      return null;
    }

    final nome = emailLimpo
        .split('@')
        .first
        .replaceAll('.', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .map(
          (parte) =>
              parte.isEmpty ? '' : parte[0].toUpperCase() + parte.substring(1),
        )
        .join(' ');

    final usuario = Usuario(
      email: emailLimpo,
      nome: nome.isEmpty ? 'Usuário' : nome,
      isAdmin: true,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(usuario.toJson()));
    return usuario;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
