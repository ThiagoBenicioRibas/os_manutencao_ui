
import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pelo registro e pela consulta do histórico
/// de status das ordens de serviço no SQLite.
class HistoricoStatusRepository {
  HistoricoStatusRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Registra uma mudança de status e retorna o ID gerado.
  Future<int> inserir(HistoricoStatus historico) async {
    if (historico.statusNovo.trim().isEmpty) {
      throw ArgumentError(
        'O novo status não pode estar vazio.',
      );
    }

    final banco = await _databaseService.database;

    final dados = historico.toMap()..remove('id');

    return banco.insert('historico_status', dados);
  }

  /// Consulta um registro de histórico pelo identificador.
  ///
  /// Retorna null quando o registro não existe.
  Future<HistoricoStatus?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'historico_status',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return HistoricoStatus.fromMap(registros.first);
  }

  /// Lista o histórico de uma ordem de serviço.
  ///
  /// Os registros são apresentados do mais antigo
  /// para o mais recente.
  Future<List<HistoricoStatus>> listarPorOrdem(int ordemId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'historico_status',
      where: 'ordem_id = ?',
      whereArgs: [ordemId],
      orderBy: 'data_alteracao ASC, id ASC',
    );

    return registros.map(HistoricoStatus.fromMap).toList();
  }

  /// Lista todos os registros de histórico do sistema.
  Future<List<HistoricoStatus>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'historico_status',
      orderBy: 'data_alteracao DESC, id DESC',
    );

    return registros.map(HistoricoStatus.fromMap).toList();
  }
}
