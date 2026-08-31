import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movimentacao_model.dart';
import '../services/supabase_service.dart';

class MovimentacaoRepository {
  static const String _storageKey = 'fideliz_historico';

  static Future<List<Movimentacao>> carregar() async {
    if (SupabaseService.isConfigured) {
      try {
        final response = await SupabaseService.client
            .from('movimentacoes')
            .select();

        if (response is List) {
          return response
              .map((item) => Movimentacao.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      } catch (_) {
        // Fallback para o histórico local enquanto o backend real ainda não
        // reúne o mesmo payload do fluxo atual.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final dados = prefs.getString(_storageKey);

    if (dados == null || dados.isEmpty) {
      return const [];
    }

    final decoded = json.decode(dados);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .map((item) => Movimentacao.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> salvar(List<Movimentacao> movimentacoes) async {
    if (SupabaseService.isConfigured) {
      try {
        final payload = movimentacoes.map((mov) {
          final row = mov.toJson();
          final userId = SupabaseService.currentUserId;
          if (userId != null && !row.containsKey('profile_id')) {
            row['profile_id'] = userId;
          }
          return row;
        }).toList();

        await SupabaseService.client.from('movimentacoes').upsert(
          payload,
          onConflict: 'id',
        );
        return;
      } catch (_) {
        // Fallback para persistência local até o schema real do banco refletir
        // as mesmas chaves do MVP.
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final data = movimentacoes.map((mov) => mov.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(data));
  }

  static int calcularPontosPorCompra(double valor) {
    if (valor <= 0) {
      return 0;
    }

    return (valor / 10).floor();
  }

  static Map<String, dynamic> resumo(List<Movimentacao> movimentacoes) {
    final compras = movimentacoes.where((item) => item.tipo == 'compra').toList();
    final valorTotalCompras = compras.fold<double>(
      0,
      (total, item) => total + item.valor,
    );
    final ticketMedio = compras.isEmpty ? 0.0 : valorTotalCompras / compras.length;

    return {
      'totalMovimentacoes': movimentacoes.length,
      'totalCompras': compras.length,
      'valorTotalCompras': valorTotalCompras,
      'ticketMedio': ticketMedio,
      'ultimasPontos': movimentacoes.isEmpty ? 0 : movimentacoes.first.pontos,
    };
  }
}
