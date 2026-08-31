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

  static Future<Usuario?> _carregarUsuarioDoSupabase() async {
    final user = SupabaseService.client.auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final perfil = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final perfilMap = perfil is Map
          ? Map<String, dynamic>.from(perfil as Map<dynamic, dynamic>)
          : null;
      final nome = perfilMap != null && perfilMap['full_name'] != null
          ? perfilMap['full_name'].toString()
          : (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  _nomePadraoDoEmail(user.email ?? ''))
              .toString();

      final usuario = Usuario(
        email: user.email ?? '',
        nome: nome,
        isAdmin: true,
      );

      if (usuario.email.isNotEmpty) {
        await _salvarSessaoLocal(usuario);
      }

      return usuario.email.isEmpty ? null : usuario;
    } catch (_) {
      return null;
    }
  }

  static Future<Usuario?> carregarSessao() async {
    if (SupabaseService.isConfigured) {
      try {
        final usuario = await _carregarUsuarioDoSupabase();
        if (usuario != null) {
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

        final usuario = await _carregarUsuarioDoSupabase();
        if (usuario != null) {
          return usuario;
        }

        final user = resposta.user;
        if (user == null) {
          return null;
        }

        final fallbackUsuario = Usuario(
          email: user.email ?? emailLimpo,
          nome: (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  _nomePadraoDoEmail(user.email ?? emailLimpo))
              .toString(),
          isAdmin: true,
        );

        await _salvarSessaoLocal(fallbackUsuario);
        return fallbackUsuario;
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

  static Future<Usuario?> registrar({
    required String email,
    required String senha,
    required String nome,
  }) async {
    final emailLimpo = email.trim();
    final senhaLimpa = senha.trim();
    final nomeLimpo = nome.trim();

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailLimpo)) {
      return null;
    }

    if (senhaLimpa.length < 6) {
      return null;
    }

    if (nomeLimpo.isEmpty) {
      return null;
    }

    if (!SupabaseService.isConfigured) {
      final usuario = Usuario(
        email: emailLimpo,
        nome: nomeLimpo,
        isAdmin: true,
      );
      await _salvarSessaoLocal(usuario);
      return usuario;
    }

    try {
      final resposta = await SupabaseService.client.auth.signUp(
        email: emailLimpo,
        password: senhaLimpa,
        data: {'full_name': nomeLimpo},
      );

      final user = resposta.user;
      if (user == null) {
        return null;
      }

      await SupabaseService.client.from('profiles').upsert({
        'id': user.id,
        'email': emailLimpo,
        'full_name': nomeLimpo,
        'role': 'admin',
      }, onConflict: 'id');

      final usuario = Usuario(
        email: user.email ?? emailLimpo,
        nome: nomeLimpo,
        isAdmin: true,
      );

      await _salvarSessaoLocal(usuario);
      return usuario;
    } catch (_) {
      return null;
    }
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
