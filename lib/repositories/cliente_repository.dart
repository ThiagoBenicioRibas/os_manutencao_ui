
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pelas operações de clientes no banco SQLite.
class ClienteRepository {
  ClienteRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Cadastra um cliente e retorna o ID gerado pelo SQLite.
  Future<int> inserir(Cliente cliente) async {
    final banco = await _databaseService.database;

    final dados = cliente.toMap()..remove('id');

    return banco.insert('clientes', dados);
  }

  /// Retorna todos os clientes em ordem alfabética.
  Future<List<Cliente>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'clientes',
      orderBy: 'nome COLLATE NOCASE ASC',
    );

    return registros.map(Cliente.fromMap).toList();
  }

  /// Busca um cliente pelo identificador.
  ///
  /// Retorna null quando o cliente não existe.
  Future<Cliente?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return Cliente.fromMap(registros.first);
  }

  /// Atualiza os dados de um cliente já cadastrado.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Cliente cliente) async {
    final id = cliente.id;

    if (id == null) {
      throw ArgumentError(
        'O cliente precisa de um ID para ser atualizado.',
      );
    }

    final banco = await _databaseService.database;

    final dados = cliente.toMap()..remove('id');

    return banco.update(
      'clientes',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui um cliente pelo identificador.
  ///
  /// O SQLite impedirá a exclusão se houver registros
  /// relacionados protegidos por chaves estrangeiras.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'clientes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
