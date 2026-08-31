class Movimentacao {
  final String id;
  final String clienteId;
  final String clienteNome;
  final String tipo;
  final int pontos;
  final double valor;
  final DateTime data;
  final String descricao;
  final String categoriaCliente;

  const Movimentacao({
    required this.id,
    this.clienteId = '',
    required this.clienteNome,
    required this.tipo,
    required this.pontos,
    required this.valor,
    required this.data,
    required this.descricao,
    this.categoriaCliente = 'comum',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'tipo': tipo,
      'pontos': pontos,
      'valor': valor,
      'data': data.toIso8601String(),
      'descricao': descricao,
      'categoriaCliente': categoriaCliente,
    };
  }

  factory Movimentacao.fromJson(Map<String, dynamic> json) {
    final valor = double.tryParse((json['valor'] ?? '0').toString()) ?? 0.0;
    final pontos = int.tryParse((json['pontos'] ?? '0').toString()) ?? 0;

    return Movimentacao(
      id: (json['id'] ?? '').toString(),
      clienteId: (json['clienteId'] ?? '').toString(),
      clienteNome: (json['clienteNome'] ?? '').toString(),
      tipo: (json['tipo'] ?? 'compra').toString(),
      pontos: pontos,
      valor: valor,
      data:
          DateTime.tryParse((json['data'] ?? '').toString()) ?? DateTime.now(),
      descricao: (json['descricao'] ?? '').toString(),
      categoriaCliente: (json['categoriaCliente'] ?? 'comum').toString(),
    );
  }
}
