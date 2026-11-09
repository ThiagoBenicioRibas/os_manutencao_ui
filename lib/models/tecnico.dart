
/// Representa um técnico cadastrado no sistema de manutenção técnica.
class Tecnico {
  final int? id;
  final String nome;
  final String contato;
  final String especialidade;
  final String situacao;

  const Tecnico({
    this.id,
    required this.nome,
    required this.contato,
    required this.especialidade,
    required this.situacao,
  });

  /// Converte um registro do SQLite em um objeto Tecnico.
  factory Tecnico.fromMap(Map<String, Object?> map) {
    return Tecnico(
      id: map['id'] as int?,
      nome: map['nome'] as String,
      contato: map['contato'] as String,
      especialidade: map['especialidade'] as String,
      situacao: map['situacao'] as String,
    );
  }

  /// Converte o técnico em dados que poderão ser salvos no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'nome': nome,
      'contato': contato,
      'especialidade': especialidade,
      'situacao': situacao,
    };
  }
}
