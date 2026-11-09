
/// Representa uma alteração de status de uma ordem de serviço.
class HistoricoStatus {
  final int? id;
  final int ordemId;
  final String? statusAnterior;
  final String statusNovo;
  final DateTime dataAlteracao;
  final String? observacao;

  const HistoricoStatus({
    this.id,
    required this.ordemId,
    this.statusAnterior,
    required this.statusNovo,
    required this.dataAlteracao,
    this.observacao,
  });

  /// Converte um registro do SQLite em um objeto HistoricoStatus.
  factory HistoricoStatus.fromMap(Map<String, Object?> map) {
    return HistoricoStatus(
      id: map['id'] as int?,
      ordemId: map['ordem_id'] as int,
      statusAnterior: map['status_anterior'] as String?,
      statusNovo: map['status_novo'] as String,
      dataAlteracao: DateTime.parse(
        map['data_alteracao'] as String,
      ),
      observacao: map['observacao'] as String?,
    );
  }

  /// Converte o histórico em dados para armazenamento no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'ordem_id': ordemId,
      'status_anterior': statusAnterior,
      'status_novo': statusNovo,
      'data_alteracao': dataAlteracao.toIso8601String(),
      'observacao': observacao,
    };
  }
}
