
/// Representa um cliente cadastrado no sistema de manutenção técnica.
class Cliente {
  final int? id;
  final String nome;
  final String documento;
  final String telefone;
  final String? email;
  final String? endereco;

  const Cliente({
    this.id,
    required this.nome,
    required this.documento,
    required this.telefone,
    this.email,
    this.endereco,
  });

  /// Converte um registro do SQLite em um objeto Cliente.
  factory Cliente.fromMap(Map<String, Object?> map) {
    return Cliente(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      documento: map['documento'] as String,
      telefone: map['telefone'] as String,
      email: map['email'] as String?,
      endereco: map['endereco'] as String?,
    );
  }

  /// Converte o cliente em dados que poderão ser salvos no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'documento': documento,
      'telefone': telefone,
      'email': email,
      'endereco': endereco,
    };
  }
}
