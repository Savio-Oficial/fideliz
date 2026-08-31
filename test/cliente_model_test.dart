import 'package:flutter_test/flutter_test.dart';
import 'package:fideliz/models/cliente_model.dart';
import 'package:fideliz/models/movimentacao_model.dart';
import 'package:fideliz/repositories/cliente_repository.dart';
import 'package:fideliz/repositories/movimentacao_repository.dart';

void main() {
  group('Cliente', () {
    test('converte de JSON com valores válidos', () {
      final cliente = Cliente.fromJson({'nome': 'João', 'pontos': '120'});

      expect(cliente.nome, 'João');
      expect(cliente.pontos, 120);
    });

    test('normaliza pontos negativos para zero', () {
      final cliente = Cliente.fromJson({'nome': 'Ana', 'pontos': '-10'});

      expect(cliente.pontos, 0);
    });
  });

  group('ClienteRepository', () {
    test('valida nome e pontos com mensagens adequadas', () {
      expect(ClienteRepository.validarNome('A'), isNotNull);
      expect(ClienteRepository.validarNome('Maria'), isNull);
      expect(ClienteRepository.validarPontos('-1'), isNotNull);
      expect(ClienteRepository.validarPontos('250'), isNull);
    });

    test('adiciona e debita pontos respeitando regras de negócio', () {
      const cliente = Cliente(nome: 'Maria', pontos: 100);

      final comBonus = ClienteRepository.adicionarPontos(cliente, 40);
      expect(comBonus.pontos, 140);

      final resgatado = ClienteRepository.debitarPontos(comBonus, 200);
      expect(resgatado.pontos, 0);
    });

    test('resumo centraliza totais do programa', () {
      final clientes = [
        const Cliente(nome: 'A', pontos: 30),
        const Cliente(nome: 'B', pontos: 90),
      ];

      final resumo = ClienteRepository.resumo(clientes);

      expect(resumo['totalClientes'], 2);
      expect(resumo['totalPontos'], 120);
      expect((resumo['maiorPontuador'] as Cliente).nome, 'B');
    });

    test('cliente sem id gera identificador estável no JSON', () {
      final cliente = Cliente.fromJson({'nome': 'Bia', 'pontos': '50'});

      expect(cliente.id, isNotEmpty);
      expect(cliente.toJson()['id'], cliente.id);
    });

    test('cliente premium recebe multiplicador de pontos na compra', () {
      const cliente = Cliente(nome: 'Carlos', pontos: 10, categoria: 'premium');

      final pontos = ClienteRepository.calcularPontosPorCompra(cliente, 120);

      expect(pontos, 18);
    });
  });

  group('MovimentacaoRepository', () {
    test('resumo calcula valor total e ticket medio', () {
      final movimentacoes = [
        Movimentacao(
          id: '1',
          clienteId: 'c1',
          clienteNome: 'Ana',
          tipo: 'compra',
          pontos: 10,
          valor: 90,
          data: DateTime(2024, 1, 1),
          descricao: 'Compra',
        ),
        Movimentacao(
          id: '2',
          clienteId: 'c1',
          clienteNome: 'Ana',
          tipo: 'compra',
          pontos: 15,
          valor: 120,
          data: DateTime(2024, 1, 2),
          descricao: 'Compra',
        ),
      ];

      final resumo = MovimentacaoRepository.resumo(movimentacoes);

      expect(resumo['totalCompras'], 2);
      expect(resumo['valorTotalCompras'], 210.0);
      expect(resumo['ticketMedio'], 105.0);
    });
  });
}
