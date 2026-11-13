
import 'package:os_manutencao_ui/models/evidencia.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pela persistência das evidências no SQLite.
///
/// Armazena os dados e os caminhos das imagens.
/// O gerenciamento dos arquivos físicos será realizado
/// separadamente.
class EvidenciaRepository {
  EvidenciaRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Valida os dados obrigatórios de uma evidência.
  void _validar(Evidencia evidencia) {
    if (evidencia.ordemId <= 0) {
      throw ArgumentError(
        'Informe uma ordem de serviço válida.',
      );
    }

    if (evidencia.caminhoArquivo.trim().isEmpty) {
      throw ArgumentError(
        'Informe o caminho do arquivo da evidência.',
      );
    }
  }

  /// Cadastra uma evidência e retorna o ID gerado.
  ///
  /// A ordem de serviço deve existir no SQLite.
  Future<int> inserir(Evidencia evidencia) async {
    _validar(evidencia);

    final banco = await _databaseService.database;

    final dados = evidencia.toMap()..remove('id');

    return banco.insert(
      'evidencias',
      dados,
    );
  }

  /// Busca uma evidência pelo identificador.
  ///
  /// Retorna null quando não existe.
  Future<Evidencia?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'evidencias',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return Evidencia.fromMap(registros.first);
  }

  /// Lista as evidências de uma ordem de serviço.
  ///
  /// Apresenta primeiro as evidências mais recentes.
  Future<List<Evidencia>> listarPorOrdem(int ordemId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'evidencias',
      where: 'ordem_id = ?',
      whereArgs: [ordemId],
      orderBy: 'data_registro DESC, id DESC',
    );

    return registros.map(Evidencia.fromMap).toList();
  }

  /// Lista todas as evidências cadastradas.
  Future<List<Evidencia>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'evidencias',
      orderBy: 'data_registro DESC, id DESC',
    );

    return registros.map(Evidencia.fromMap).toList();
  }

  /// Atualiza os dados de uma evidência existente.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Evidencia evidencia) async {
    final id = evidencia.id;

    if (id == null) {
      throw ArgumentError(
        'A evidência precisa de um ID para ser atualizada.',
      );
    }

    _validar(evidencia);

    final banco = await _databaseService.database;

    final dados = evidencia.toMap()..remove('id');

    return banco.update(
      'evidencias',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui o registro de uma evidência pelo ID.
  ///
  /// Retorna a quantidade de registros excluídos.
  ///
  /// Este método não apaga o arquivo físico da imagem.
  /// Essa operação deverá ser coordenada pela camada
  /// responsável pelo armazenamento dos arquivos.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'evidencias',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
