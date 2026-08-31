import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/usuario_model.dart';
import 'supabase_service.dart';

class AuthService {
  static const String _storageKey = 'fideliz_usuario';

  static Future<Usuario?> _carregarSessaoLocal() async {
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

  static Future<void> _salvarSessaoLocal(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(usuario.toJson()));
  }

  static Future<void> _limparSessaoLocal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  static String _nomePadraoDoEmail(String email) {
    final nome = email
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

    return nome.isEmpty ? 'Usuário' : nome;
  }

  static Future<Usuario?> carregarSessao() async {
    if (SupabaseService.isConfigured) {
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user == null) {
          return _carregarSessaoLocal();
        }

        final usuario = Usuario(
          email: user.email ?? '',
          nome: (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  _nomePadraoDoEmail(user.email ?? ''))
              .toString(),
          isAdmin: true,
        );

        if (usuario.email.isNotEmpty) {
          await _salvarSessaoLocal(usuario);
          return usuario;
        }
      } catch (_) {
        return _carregarSessaoLocal();
      }
    }

    return _carregarSessaoLocal();
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

    if (SupabaseService.isConfigured) {
      try {
        final resposta = await SupabaseService.client.auth.signInWithPassword(
          email: emailLimpo,
          password: senhaLimpa,
        );

        final user = resposta.user;
        if (user == null) {
          return null;
        }

        final usuario = Usuario(
          email: user.email ?? emailLimpo,
          nome: (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  _nomePadraoDoEmail(user.email ?? emailLimpo))
              .toString(),
          isAdmin: true,
        );

        await _salvarSessaoLocal(usuario);
        return usuario;
      } catch (_) {
        return null;
      }
    }

    final usuario = Usuario(
      email: emailLimpo,
      nome: _nomePadraoDoEmail(emailLimpo),
      isAdmin: true,
    );

    await _salvarSessaoLocal(usuario);
    return usuario;
  }

  static Future<void> logout() async {
    if (SupabaseService.isConfigured) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (_) {}
    }

    await _limparSessaoLocal();
  }
}
