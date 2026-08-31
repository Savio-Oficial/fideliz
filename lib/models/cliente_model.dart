class Cliente {
  final String id;
  final String nome;
  final int pontos;
  final String categoria;

  const Cliente({
    this.id = '',
    required this.nome,
    required this.pontos,
    this.categoria = 'comum',
  });

  static const List<String> categoriasDisponiveis = ['comum', 'ouro', 'premium'];

  static String gerarId() => DateTime.now().microsecondsSinceEpoch.toString();

  String get categoriaLabel {
    switch (categoria) {
      case 'ouro':
        return 'Ouro';
      case 'premium':
        return 'Premium';
      case 'comum':
      default:
        return 'Comum';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id.isNotEmpty ? id : gerarId(),
      'nome': nome.trim(),
      'pontos': pontos,
      'categoria': categoria,
    };
  }

  factory Cliente.fromJson(Map<String, dynamic> json) {
    final nome = (json['nome'] ?? '').toString().trim();
    final pontos = int.tryParse((json['pontos'] ?? '0').toString()) ?? 0;
    final id = (json['id'] ?? '').toString();
    final categoria = (json['categoria'] ?? 'comum').toString().toLowerCase();

    return Cliente(
      id: id.isNotEmpty ? id : '${nome.isNotEmpty ? nome : 'cliente'}-${gerarId()}',
      nome: nome,
      pontos: pontos < 0 ? 0 : pontos,
      categoria: categoriasDisponiveis.contains(categoria) ? categoria : 'comum',
    );
  }

  Cliente copyWith({String? id, String? nome, int? pontos, String? categoria}) {
    return Cliente(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      pontos: pontos ?? this.pontos,
      categoria: categoria ?? this.categoria,
    );
  }
}
