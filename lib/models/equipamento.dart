
/// Representa um equipamento pertencente a um cliente.
class Equipamento {
  final int? id;
  final int clienteId;
  final String tipo;
  final String? marca;
  final String? modelo;
  final String? numeroSerie;
  final String? patrimonio;
  final String? observacoes;

  const Equipamento({
    this.id,
    required this.clienteId,
    required this.tipo,
    this.marca,
    this.modelo,
    this.numeroSerie,
    this.patrimonio,
    this.observacoes,
  });

  /// Converte um registro do SQLite em um objeto Equipamento.
  factory Equipamento.fromMap(Map<String, Object?> map) {
    return Equipamento(
      id: map['id'] as int?,
      clienteId: map['cliente_id'] as int,
      tipo: map['tipo'] as String,
      marca: map['marca'] as String?,
      modelo: map['modelo'] as String?,
      numeroSerie: map['numero_serie'] as String?,
      patrimonio: map['patrimonio'] as String?,
      observacoes: map['observacoes'] as String?,
    );
  }

  /// Converte o equipamento em dados para o SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'cliente_id': clienteId,
      'tipo': tipo,
      'marca': marca,
      'modelo': modelo,
      'numero_serie': numeroSerie,
      'patrimonio': patrimonio,
      'observacoes': observacoes,
    };
  }
}
