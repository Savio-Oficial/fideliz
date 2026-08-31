import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/movimentacao_model.dart';

class MovimentacaoRepository {
  static const String _storageKey = 'fideliz_historico';

  static Future<List<Movimentacao>> carregar() async {
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
