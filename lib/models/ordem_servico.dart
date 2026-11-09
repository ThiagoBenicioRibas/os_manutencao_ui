
/// Representa uma ordem de serviço de manutenção técnica.
class OrdemServico {
  final int? id;
  final String codigo;
  final int clienteId;
  final int equipamentoId;
  final int? tecnicoId;

  final String descricaoProblema;
  final String prioridade;
  final String status;

  final DateTime dataAbertura;
  final DateTime? prazoPrevisto;
  final DateTime? dataConclusao;

  final String? diagnostico;
  final String? solucao;
  final String? observacoesAtendimento;

  final int valorMaoObraCentavos;

  const OrdemServico({
    this.id,
    required this.codigo,
    required this.clienteId,
    required this.equipamentoId,
    this.tecnicoId,
    required this.descricaoProblema,
    required this.prioridade,
    required this.status,
    required this.dataAbertura,
    this.prazoPrevisto,
    this.dataConclusao,
    this.diagnostico,
    this.solucao,
    this.observacoesAtendimento,
    this.valorMaoObraCentavos = 0,
  });

  /// Converte um registro do SQLite em uma OrdemServico.
  factory OrdemServico.fromMap(Map<String, Object?> map) {
    return OrdemServico(
      id: map['id'] as int?,
      codigo: map['codigo'] as String,
      clienteId: map['cliente_id'] as int,
      equipamentoId: map['equipamento_id'] as int,
      tecnicoId: map['tecnico_id'] as int?,
      descricaoProblema: map['descricao_problema'] as String,
      prioridade: map['prioridade'] as String,
      status: map['status'] as String,
      dataAbertura: DateTime.parse(
        map['data_abertura'] as String,
      ),
      prazoPrevisto: map['prazo_previsto'] == null
          ? null
          : DateTime.parse(map['prazo_previsto'] as String),
      dataConclusao: map['data_conclusao'] == null
          ? null
          : DateTime.parse(map['data_conclusao'] as String),
      diagnostico: map['diagnostico'] as String?,
      solucao: map['solucao'] as String?,
      observacoesAtendimento:
          map['observacoes_atendimento'] as String?,
      valorMaoObraCentavos:
          map['valor_mao_obra_centavos'] as int,
    );
  }

  /// Converte a ordem em dados para armazenamento no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'codigo': codigo,
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'tecnico_id': tecnicoId,
      'descricao_problema': descricaoProblema,
      'prioridade': prioridade,
      'status': status,
      'data_abertura': dataAbertura.toIso8601String(),
      'prazo_previsto': prazoPrevisto?.toIso8601String(),
      'data_conclusao': dataConclusao?.toIso8601String(),
      'diagnostico': diagnostico,
      'solucao': solucao,
      'observacoes_atendimento': observacoesAtendimento,
      'valor_mao_obra_centavos': valorMaoObraCentavos,
    };
  }
}
