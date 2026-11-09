
/// Representa uma peça ou material utilizado em uma ordem de serviço.
class ItemUtilizado {
  final int? id;
  final int ordemId;
  final String descricao;
  final int quantidade;
  final int valorUnitarioCentavos;

  const ItemUtilizado({
    this.id,
    required this.ordemId,
    required this.descricao,
    required this.quantidade,
    required this.valorUnitarioCentavos,
  });

  /// Calcula o subtotal do item em centavos.
  int get subtotalCentavos => quantidade * valorUnitarioCentavos;

  /// Converte um registro do SQLite em um objeto ItemUtilizado.
  factory ItemUtilizado.fromMap(Map<String, Object?> map) {
    return ItemUtilizado(
      id: map['id'] as int?,
      ordemId: map['ordem_id'] as int,
      descricao: map['descricao'] as String,
      quantidade: map['quantidade'] as int,
      valorUnitarioCentavos: map['valor_unitario_centavos'] as int,
    );
  }

  /// Converte o item em dados para armazenamento no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'ordem_id': ordemId,
      'descricao': descricao,
      'quantidade': quantidade,
      'valor_unitario_centavos': valorUnitarioCentavos,
    };
  }
}
