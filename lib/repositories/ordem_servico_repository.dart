
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Responsável pelas operações de ordens de serviço no SQLite.
class OrdemServicoRepository {
  OrdemServicoRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Verifica se o equipamento pertence ao cliente informado.
  Future<void> _validarEquipamentoCliente(
    Database banco,
    OrdemServico ordem,
  ) async {
    final equipamentos = await banco.query(
      'equipamentos',
      columns: ['id'],
      where: 'id = ? AND cliente_id = ?',
      whereArgs: [ordem.equipamentoId, ordem.clienteId],
      limit: 1,
    );

    if (equipamentos.isEmpty) {
      throw ArgumentError(
        'O equipamento informado não pertence ao cliente da ordem.',
      );
    }
  }

  /// Cadastra uma ordem e retorna o ID gerado pelo SQLite.
  Future<int> inserir(OrdemServico ordem) async {
    final banco = await _databaseService.database;

    await _validarEquipamentoCliente(banco, ordem);

    final dados = ordem.toMap()..remove('id');

    return banco.insert('ordens_servico', dados);
  }

  /// Lista todas as ordens, das mais recentes para as antigas.
  Future<List<OrdemServico>> listar() async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'ordens_servico',
      orderBy: 'data_abertura DESC, id DESC',
    );

    return registros.map(OrdemServico.fromMap).toList();
  }

  /// Busca uma ordem pelo identificador.
  ///
  /// Retorna null quando a ordem não existe.
  Future<OrdemServico?> buscarPorId(int id) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'ordens_servico',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (registros.isEmpty) {
      return null;
    }

    return OrdemServico.fromMap(registros.first);
  }

  /// Lista as ordens associadas a determinado cliente.
  Future<List<OrdemServico>> listarPorCliente(int clienteId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'ordens_servico',
      where: 'cliente_id = ?',
      whereArgs: [clienteId],
      orderBy: 'data_abertura DESC, id DESC',
    );

    return registros.map(OrdemServico.fromMap).toList();
  }

  /// Lista as ordens atribuídas a determinado técnico.
  Future<List<OrdemServico>> listarPorTecnico(int tecnicoId) async {
    final banco = await _databaseService.database;

    final registros = await banco.query(
      'ordens_servico',
      where: 'tecnico_id = ?',
      whereArgs: [tecnicoId],
      orderBy: 'data_abertura DESC, id DESC',
    );

    return registros.map(OrdemServico.fromMap).toList();
  }

  /// Atualiza uma ordem de serviço existente.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(OrdemServico ordem) async {
    final id = ordem.id;

    if (id == null) {
      throw ArgumentError(
        'A ordem de serviço precisa de um ID para ser atualizada.',
      );
    }

    final banco = await _databaseService.database;

    await _validarEquipamentoCliente(banco, ordem);

    final dados = ordem.toMap()..remove('id');

    return banco.update(
      'ordens_servico',
      dados,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Exclui uma ordem de serviço pelo identificador.
  ///
  /// O SQLite removerá os registros dependentes configurados
  /// com ON DELETE CASCADE, como itens e histórico.
  ///
  /// Arquivos físicos de evidências exigem tratamento separado.
  Future<int> excluir(int id) async {
    final banco = await _databaseService.database;

    return banco.delete(
      'ordens_servico',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
