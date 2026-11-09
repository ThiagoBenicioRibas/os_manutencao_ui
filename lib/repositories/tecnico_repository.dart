
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pelas operações de técnicos no banco SQLite.
class TecnicoRepository {
  TecnicoRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Cadastra um técnico e retorna o ID gerado pelo SQLite.
  Future<int> inserir(Tecnico tecnico) async {
    final banco = await _databaseService.database;

    final dados = tecnico.toMap()..remove('id');

    return banco.insert('tecnicos', dados);
  }

  /// Retorna todos os técnicos em ordem alfabética.
  Future<List<Tecnico>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'tecnicos',
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return registros.map(Tecnico.fromMap).toList();
  }

  /// Busca um técnico pelo identificador.
  ///
  /// Retorna null quando o técnico não existe.
  Future<Tecnico?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'tecnicos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return Tecnico.fromMap(registros.first);
  }

  /// Atualiza os dados de um técnico cadastrado.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Tecnico tecnico) async {
    final id = tecnico.id;

    if (id == null) {
      throw ArgumentError(
        'O técnico precisa de um ID para ser atualizado.',
      );
    }

    final banco = await _databaseService.database;

    final dados = tecnico.toMap()..remove('id');

    return banco.update(
      'tecnicos',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui um técnico pelo identificador.
  ///
  /// O SQLite impedirá a exclusão se o técnico possuir
  /// ordens de serviço vinculadas por chave estrangeira.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'tecnicos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
