
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/services/database_service.dart';

/// Responsável pelos itens utilizados nas ordens de serviço.
class ItemUtilizadoRepository {
  ItemUtilizadoRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Cadastra um item e retorna o identificador gerado.
  Future<int> inserir(ItemUtilizado item) async {
    _validar(item);

    final banco = await _databaseService.database;
    final dados = item.toMap()..remove('id');

    return banco.insert('itens_utilizados', dados);
  }

  /// Lista todos os itens cadastrados.
  Future<List<ItemUtilizado>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'itens_utilizados',
      orderBy: 'id ASC',
    );

    return registros.map(ItemUtilizado.fromMap).toList();
  }

  /// Consulta um item pelo identificador.
  Future<ItemUtilizado?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'itens_utilizados',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return ItemUtilizado.fromMap(registros.first);
  }

  /// Lista os itens pertencentes a uma ordem de serviço.
  Future<List<ItemUtilizado>> listarPorOrdem(int ordemId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'itens_utilizados',
      where: 'ordem_id = ?',
      whereArgs: [ordemId],
      orderBy: 'id ASC',
    );

    return registros.map(ItemUtilizado.fromMap).toList();
  }

  /// Atualiza os dados de um item existente.
  Future<int> atualizar(ItemUtilizado item) async {
    final id = item.id;

    if (id == null) {
      throw ArgumentError(
        'O item precisa de um ID para ser atualizado.',
      );
    }

    _validar(item);

    final banco = await _databaseService.database;
    final dados = item.toMap()..remove('id');

    return banco.update(
      'itens_utilizados',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui um item pelo identificador.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'itens_utilizados',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Soma os subtotais de todos os itens de uma ordem.
  ///
  /// O resultado é expresso em centavos.
  Future<int> calcularTotalCentavos(int ordemId) async {
    final banco = await _databaseService.database;

    final resultado = await banco.rawQuery(
      '''
      SELECT COALESCE(
        SUM(quantidade * valor_unitario_centavos),
        0
      ) AS total
      FROM itens_utilizados
      WHERE ordem_id = ?
      ''',
      [ordemId],
    );

    return resultado.first['total'] as int;
  }

  /// Valida as informações básicas de um item.
  void _validar(ItemUtilizado item) {
    if (item.descricao.trim().isEmpty) {
      throw ArgumentError('A descrição do item é obrigatória.');
    }

    if (item.quantidade <= 0) {
      throw ArgumentError(
        'A quantidade deve ser maior que zero.',
      );
    }

    if (item.valorUnitarioCentavos < 0) {
      throw ArgumentError(
        'O valor unitário não pode ser negativo.',
      );
    }
  }
}
