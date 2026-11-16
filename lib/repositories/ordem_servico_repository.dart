import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:os_manutencao_ui/services/regras_ordem_servico.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Responsável pelas operações de ordens de serviço no SQLite.
class OrdemServicoRepository {
  OrdemServicoRepository({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService.instance;

  final DatabaseService _databaseService;

  /// Verifica se o equipamento pertence ao cliente informado.
  Future<void> _validarEquipamentoCliente(
    DatabaseExecutor banco,
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

  /// Atualiza os dados de uma ordem existente.
  ///
  /// Impede mudanças de status por este método.
  /// Para alterar o status e registrar o histórico,
  /// utilize alterarStatus.
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

    return banco.transaction((transacao) async {
      final registros = await transacao.query(
        'ordens_servico',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (registros.isEmpty) {
        throw StateError('A ordem não foi encontrada. Atualize a lista.');
      }
      final atual = OrdemServico.fromMap(registros.single);
      if (ordem.status != atual.status) {
        throw StateError('O status mudou. Reabra a ordem antes de editar.');
      }
      final exigeTecnico = [
        'Atribuída',
        'Em atendimento',
        'Aguardando peça',
        'Concluída'
      ].contains(atual.status);
      if (exigeTecnico && ordem.tecnicoId == null) {
        throw StateError('Mantenha um técnico responsável neste status.');
      }
      if (atual.status == 'Concluída' &&
          ((ordem.diagnostico?.trim().isEmpty ?? true) ||
              (ordem.solucao?.trim().isEmpty ?? true))) {
        throw StateError(
            'Uma ordem concluída precisa de diagnóstico e solução.');
      }
      await _validarEquipamentoCliente(transacao, ordem);
      final dados = ordem.toMap()
        ..remove('id')
        ..remove('status')
        ..remove('data_conclusao');
      return transacao.update(
        'ordens_servico',
        dados,
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  /// Altera o status de uma ordem e registra seu histórico.
  ///
  /// As duas gravações acontecem na mesma transação SQLite.
  /// Caso uma delas falhe, nenhuma alteração é confirmada.
  Future<void> alterarStatus({
    required int ordemId,
    required String novoStatus,
    String? observacao,
  }) async {
    final banco = await _databaseService.database;

    await banco.transaction((transacao) async {
      // Consulta o estado atual dentro da transação.
      final registros = await transacao.query(
        'ordens_servico',
        where: 'id = ?',
        whereArgs: [ordemId],
        limit: 1,
      );

      if (registros.isEmpty) {
        throw StateError(
          'A ordem de serviço $ordemId não foi encontrada.',
        );
      }

      final ordemAtual = OrdemServico.fromMap(registros.first);

      // Valida a mudança antes de gravar qualquer informação.
      RegrasOrdemServico.validarTransicao(
        ordemAtual,
        novoStatus,
      );

      final dataAlteracao = DateTime.now();

      final dadosAtualizados = <String, Object?>{
        'status': novoStatus,
      };

      if (novoStatus == 'Concluída') {
        dadosAtualizados['data_conclusao'] = dataAlteracao.toIso8601String();
      }

      // Primeira operação: atualiza o status da OS.
      final quantidadeAtualizada = await transacao.update(
        'ordens_servico',
        dadosAtualizados,
        where: 'id = ?',
        whereArgs: [ordemId],
      );

      if (quantidadeAtualizada != 1) {
        throw StateError(
          'Não foi possível atualizar o status da ordem $ordemId.',
        );
      }

      // Segunda operação: registra a mudança no histórico.
      final historico = HistoricoStatus(
        ordemId: ordemId,
        statusAnterior: ordemAtual.status,
        statusNovo: novoStatus,
        dataAlteracao: dataAlteracao,
        observacao: observacao,
      );

      final dadosHistorico = historico.toMap()..remove('id');

      await transacao.insert(
        'historico_status',
        dadosHistorico,
      );

      // O SQLite confirma as duas alterações conjuntamente.
    });
  }

  /// Exclui uma ordem de serviço pelo identificador.
  ///
  /// Registros dependentes com ON DELETE CASCADE
  /// serão removidos automaticamente pelo SQLite.
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
