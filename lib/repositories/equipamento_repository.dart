
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pelas operações de equipamentos no SQLite.
class EquipamentoRepository {
  EquipamentoRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Cadastra um equipamento e retorna o ID gerado pelo SQLite.
  Future<int> inserir(Equipamento equipamento) async {
    final banco = await _databaseService.database;

    final dados = equipamento.toMap()..remove('id');

    return banco.insert('equipamentos', dados);
  }

  /// Lista todos os equipamentos ordenados por tipo e ID.
  Future<List<Equipamento>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'equipamentos',
      orderBy: 'tipo COLLATE NOCASE ASC, id ASC',
    );

    return registros.map(Equipamento.fromMap).toList();
  }

  /// Busca um equipamento pelo identificador.
  ///
  /// Retorna null quando o equipamento não existe.
  Future<Equipamento?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'equipamentos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return Equipamento.fromMap(registros.first);
  }

  /// Lista os equipamentos pertencentes a determinado cliente.
  Future<List<Equipamento>> listarPorCliente(int clienteId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'equipamentos',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'tipo COLLATE NOCASE ASC, id ASC',
    );

    return registros.map(Equipamento.fromMap).toList();
  }

  /// Atualiza os dados de um equipamento cadastrado.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Equipamento equipamento) async {
    final id = equipamento.id;

    if (id == null) {
      throw ArgumentError(
        'O equipamento precisa de um ID para ser atualizado.',
      );
    }

    final banco = await _databaseService.database;

    final dados = equipamento.toMap()..remove('id');

    return banco.update(
      'equipamentos',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui um equipamento pelo identificador.
  ///
  /// O SQLite impedirá a exclusão se houver ordens
  /// de serviço vinculadas ao equipamento.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'equipamentos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
