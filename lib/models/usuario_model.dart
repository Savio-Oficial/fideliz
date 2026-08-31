class Usuario {
  final String email;
  final String nome;
  final bool isAdmin;

  const Usuario({required this.email, required this.nome, this.isAdmin = true});

  String get nomeExibicao => nome.isNotEmpty ? nome : 'Usuário';

  Map<String, dynamic> toJson() {
    return {'email': email, 'nome': nome, 'isAdmin': isAdmin};
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      email: (json['email'] ?? '').toString(),
      nome: (json['nome'] ?? 'Usuário').toString(),
      isAdmin: json['isAdmin'] == true,
    );
  }
}
