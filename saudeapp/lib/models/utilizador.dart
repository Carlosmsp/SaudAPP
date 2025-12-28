class Utilizador {
  final String id;
  final String nome;
  final String email;
  final String? fotoPerfilUrl;   // Campo opcional para a URL da foto de perfil

  Utilizador({
    required this.id,
    required this.nome,
    required this.email,
    this.fotoPerfilUrl,
  });

  factory Utilizador.fromJson(Map<String, dynamic> json) {
    return Utilizador(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      fotoPerfilUrl: json['foto_perfil_url'], // <-- NOVO campo para a URL da foto de perfil
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'foto_perfil_url': fotoPerfilUrl, // <-- NOVO campo para a URL da foto de perfil
    };
  }
}
