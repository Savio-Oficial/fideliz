import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/cliente_model.dart';

class ClienteRepository {
  static const String _storageKey = 'clientes_data';

  static Future<List<Cliente>> carregar() async {
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
        .map((item) => Cliente.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  static Future<void> salvar(List<Cliente> clientes) async {
    final prefs = await SharedPreferences.getInstance();
    final data = clientes.map((cliente) => cliente.toJson()).toList();
    await prefs.setString(_storageKey, json.encode(data));
  }

  static double multiplicadorCategoria(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'ouro':
        return 1.25;
      case 'premium':
        return 1.5;
      case 'comum':
      default:
        return 1.0;
    }
  }

  static int calcularPontosPorCompra(Cliente cliente, double valor) {
    if (valor <= 0) {
      return 0;
    }

    final base = (valor / 10).floor();
    return (base * multiplicadorCategoria(cliente.categoria)).round();
  }

  static Cliente adicionarPontos(Cliente cliente, int quantidade) {
    if (quantidade <= 0) {
      return cliente;
    }

    return cliente.copyWith(pontos: cliente.pontos + quantidade);
  }

  static Cliente debitarPontos(Cliente cliente, int quantidade) {
    if (quantidade <= 0) {
      return cliente;
    }

    final proximoSaldo = cliente.pontos - quantidade;
    return cliente.copyWith(pontos: proximoSaldo < 0 ? 0 : proximoSaldo);
  }

  static Map<String, dynamic> resumo(List<Cliente> clientes) {
    final totalPontos = clientes.fold<int>(
      0,
      (valor, cliente) => valor + cliente.pontos,
    );
    final maiorPontuador = clientes.isEmpty
        ? null
        : clientes.reduce((melhor, atual) {
            if (atual.pontos > melhor.pontos) {
              return atual;
            }
            return melhor;
          });
    final clientesVip = clientes.where((cliente) => cliente.categoria != 'comum').length;
    final categoriaMaisAtiva = clientes.isEmpty
        ? null
        : clientes
            .fold<Map<String, int>>({}, (acc, cliente) {
              final chave = cliente.categoria;
              acc[chave] = (acc[chave] ?? 0) + 1;
              return acc;
            })
            .entries
            .reduce((melhor, atual) {
              if (atual.value > melhor.value) {
                return atual;
              }
              return melhor;
            })
            .key;

    return {
      'totalClientes': clientes.length,
      'totalPontos': totalPontos,
      'maiorPontuador': maiorPontuador,
      'clientesVip': clientesVip,
      'categoriaMaisAtiva': categoriaMaisAtiva,
    };
  }

  static String? validarNome(String? nome) {
    final valor = (nome ?? '').trim();

    if (valor.isEmpty) {
      return 'Informe o nome do cliente.';
    }

    if (valor.length < 2) {
      return 'O nome deve ter pelo menos 2 caracteres.';
    }

    return null;
  }

  static String? validarPontos(String? pontos) {
    final valor = (pontos ?? '').trim();

    if (valor.isEmpty) {
      return 'Informe a quantidade de pontos.';
    }

    final pontosNumero = int.tryParse(valor);
    if (pontosNumero == null) {
      return 'Digite apenas números inteiros.';
    }

    if (pontosNumero < 0) {
      return 'Pontos não podem ser negativos.';
    }

    return null;
  }

  static String? validarMovimentoPontos(
    String? pontos, {
    required bool eDebito,
  }) {
    final valor = (pontos ?? '').trim();
    final pontosNumero = int.tryParse(valor);

    if (pontosNumero == null || pontosNumero <= 0) {
      return 'Informe um valor maior que zero.';
    }

    if (eDebito && pontosNumero <= 0) {
      return 'Para resgatar pontos, use um valor positivo.';
    }

    return null;
  }
}
