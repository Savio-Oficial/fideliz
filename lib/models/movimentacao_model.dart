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
    final metadata = json['metadata'] is Map
        ? Map<String, dynamic>.from(json['metadata'] as Map)
        : <String, dynamic>{};

    final valorRaw = json['valor'] ?? metadata['valor'] ?? '0';
    final valor = double.tryParse(valorRaw.toString()) ?? 0.0;
    final pontosRaw = json['pontos'] ?? '0';
    final pontos = int.tryParse(pontosRaw.toString()) ?? 0;
    final dataRaw = json['created_at'] ?? json['data'] ?? '';

    return Movimentacao(
      id: (json['id'] ?? '').toString(),
      clienteId: (json['cliente_id'] ?? json['clienteId'] ?? metadata['cliente_id'] ?? '')
          .toString(),
      clienteNome: (json['cliente_nome'] ??
              json['clienteNome'] ??
              metadata['cliente_nome'] ??
              '')
          .toString(),
      tipo: (json['tipo'] ?? 'compra').toString(),
      pontos: pontos,
      valor: valor,
      data: DateTime.tryParse(dataRaw.toString()) ?? DateTime.now(),
      descricao: (json['descricao'] ?? '').toString(),
      categoriaCliente: (json['categoria_cliente'] ??
              json['categoriaCliente'] ??
              metadata['categoria_cliente'] ??
              'comum')
          .toString(),
    );
  }
}
