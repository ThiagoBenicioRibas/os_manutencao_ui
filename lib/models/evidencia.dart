
/// Representa uma evidência fotográfica vinculada
/// a uma ordem de serviço.
///
/// O SQLite armazena as informações da evidência.
/// O arquivo físico da imagem é armazenado separadamente.
class Evidencia {
  final int? id;
  final int ordemId;
  final String caminhoArquivo;
  final String? descricao;
  final String? tipo;
  final DateTime dataRegistro;

  const Evidencia({
    this.id,
    required this.ordemId,
    required this.caminhoArquivo,
    this.descricao,
    this.tipo,
    required this.dataRegistro,
  });

  /// Converte um registro do SQLite em um objeto Evidencia.
  factory Evidencia.fromMap(Map<String, Object?> map) {
    return Evidencia(
      id: map['id'] as int?,
      ordemId: map['ordem_id'] as int,
      caminhoArquivo: map['caminho_arquivo'] as String,
      descricao: map['descricao'] as String?,
      tipo: map['tipo'] as String?,
      dataRegistro: DateTime.parse(
        map['data_registro'] as String,
      ),
    );
  }

  /// Converte a evidência em dados para armazenamento no SQLite.
  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'ordem_id': ordemId,
      'caminho_arquivo': caminhoArquivo,
      'descricao': descricao,
      'tipo': tipo,
      'data_registro': dataRegistro.toIso8601String(),
    };
  }
}
