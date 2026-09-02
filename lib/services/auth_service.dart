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

  static Future<Usuario?> _salvarUsuarioSupabase(
    dynamic user, {
    String? nomeFallback,
  }) async {
    if (user == null) {
      return null;
    }

    final email = (user.email ?? '').toString();
    final nome = (user.userMetadata?['full_name'] ??
                user.userMetadata?['name'] ??
                nomeFallback ??
                _nomePadraoDoEmail(email))
            .toString();

    if (SupabaseService.isConfigured && email.isNotEmpty) {
      try {
        await SupabaseService.client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'full_name': nome,
          'role': 'admin',
        }, onConflict: 'id');
      } catch (_) {
        // O perfil pode já existir ou a tabela pode ainda não estar em uso.
      }
    }

    final usuario = Usuario(
      email: email,
      nome: nome,
      isAdmin: true,
    );

    if (usuario.email.isNotEmpty) {
      await _salvarSessaoLocal(usuario);
    }

    return usuario.email.isEmpty ? null : usuario;
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

      return _salvarUsuarioSupabase(user, nomeFallback: nome);
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
    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!emailRegex.hasMatch(emailLimpo)) {
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

        return _salvarUsuarioSupabase(
          user,
          nomeFallback: (user.userMetadata?['full_name'] ??
                  user.userMetadata?['name'] ??
                  _nomePadraoDoEmail(user.email ?? emailLimpo))
              .toString(),
        );
      } catch (_) {
        // Durante a migração, o login local segue sendo válido para manter o
        // fluxo de desenvolvimento e testes enquanto o backend real ainda está
        // sendo validado.
      }
    }

    if (emailLimpo.toLowerCase() == 'admin@fideliz.com' &&
        senhaLimpa == '123456') {
      final usuario = Usuario(
        email: emailLimpo,
        nome: 'Admin',
        isAdmin: true,
      );

      await _salvarSessaoLocal(usuario);
      return usuario;
    }

    final usuarioLocal = await _carregarSessaoLocal();
    if (usuarioLocal != null &&
        usuarioLocal.email.trim().toLowerCase() == emailLimpo.toLowerCase()) {
      return usuarioLocal;
    }

    return null;
  }

  static Future<Usuario?> registrar({
    required String email,
    required String senha,
    required String nome,
  }) async {
    final emailLimpo = email.trim();
    final senhaLimpa = senha.trim();
    final nomeLimpo = nome.trim();
    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!emailRegex.hasMatch(emailLimpo)) {
      return null;
    }

    if (senhaLimpa.length < 6) {
      return null;
    }

    if (nomeLimpo.isEmpty) {
      return null;
    }

    if (SupabaseService.isConfigured) {
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

        return _salvarUsuarioSupabase(
          user,
          nomeFallback: nomeLimpo,
        );
      } catch (_) {
        // Fallback local para manter o fluxo funcional quando a autenticação
        // real ainda não está liberada ou está sendo rate-limitada.
      }
    }

    final usuario = Usuario(
      email: emailLimpo,
      nome: nomeLimpo,
      isAdmin: true,
    );
    await _salvarSessaoLocal(usuario);
    return usuario;
  }

  static Future<bool> resetarSenha({required String email}) async {
    final emailLimpo = email.trim();
    final emailRegex = RegExp(
      r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9-]+(?:\.[A-Za-z0-9-]+)+$",
    );

    if (!emailRegex.hasMatch(emailLimpo)) {
      return false;
    }

    if (SupabaseService.isConfigured) {
      try {
        await SupabaseService.client.auth.resetPasswordForEmail(emailLimpo);
        return true;
      } catch (_) {
        return false;
      }
    }

    return true;
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
