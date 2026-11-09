
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/repositories/historico_status_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late HistoricoStatusRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_historico_status_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'historico.db'),
    );

    repositorio = HistoricoStatusRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  /// Cria uma ordem de serviço válida para os testes.
  Future<int> criarOrdem(String codigo) async {
    final banco = await servico.database;

    final clienteId = await banco.insert('clientes', {
      'nome': 'Cliente $codigo',
      'documento': 'DOC-$codigo',
      'telefone': '71999990000',
    });

    final equipamentoId = await banco.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Notebook',
    });

    return banco.insert('ordens_servico', {
      'codigo': codigo,
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'descricao_problema': 'Equipamento nao liga',
      'prioridade': 'Normal',
      'status': 'Aberta',
      'data_abertura': DateTime.utc(2026, 11, 9).toIso8601String(),
      'valor_mao_obra_centavos': 0,
    });
  }

  test('Registra e consulta um evento de historico', () async {
    final ordemId = await criarOrdem('OS-HIST-001');
    final data = DateTime.utc(2026, 11, 9, 8, 30);

    final id = await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemId,
        statusAnterior: null,
        statusNovo: 'Aberta',
        dataAlteracao: data,
        observacao: 'Ordem cadastrada',
      ),
    );

    expect(id, greaterThan(0));

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.id, id);
    expect(encontrado.ordemId, ordemId);
    expect(encontrado.statusAnterior, isNull);
    expect(encontrado.statusNovo, 'Aberta');
    expect(encontrado.observacao, 'Ordem cadastrada');
    expect(encontrado.dataAlteracao.isAtSameMomentAs(data), isTrue);

    expect(await repositorio.buscarPorId(999999), isNull);
  });

  test('Lista o historico em ordem cronologica', () async {
    final ordemA = await criarOrdem('OS-HIST-002');
    final ordemB = await criarOrdem('OS-HIST-003');

    // Insere o evento mais recente primeiro.
    final idDez = await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemA,
        statusAnterior: 'Aberta',
        statusNovo: 'Atribuída',
        dataAlteracao: DateTime.utc(2026, 11, 9, 10),
      ),
    );

    final idOito = await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemA,
        statusNovo: 'Aberta',
        dataAlteracao: DateTime.utc(2026, 11, 9, 8),
      ),
    );

    final idNove = await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemB,
        statusNovo: 'Aberta',
        dataAlteracao: DateTime.utc(2026, 11, 9, 9),
      ),
    );

    // O historico da ordem A deve vir do mais antigo
    // para o mais recente, independentemente da insercao.
    final historicoA = await repositorio.listarPorOrdem(ordemA);

    expect(historicoA.length, 2);
    expect(historicoA[0].id, idOito);
    expect(historicoA[1].id, idDez);

    // Os eventos da ordem B nao podem aparecer na ordem A.
    final historicoB = await repositorio.listarPorOrdem(ordemB);

    expect(historicoB.length, 1);
    expect(historicoB.first.id, idNove);

    // A listagem geral apresenta os mais recentes primeiro.
    final todos = await repositorio.listar();

    expect(todos.length, 3);
    expect(
      todos.map((evento) => evento.id).toList(),
      [idDez, idNove, idOito],
    );
  });

  test('Rejeita um novo status vazio', () async {
    final ordemId = await criarOrdem('OS-HIST-004');

    await expectLater(
      repositorio.inserir(
        HistoricoStatus(
          ordemId: ordemId,
          statusNovo: '   ',
          dataAlteracao: DateTime.utc(2026, 11, 9, 8),
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await repositorio.listarPorOrdem(ordemId), isEmpty);
  });

  test('Impede historico vinculado a ordem inexistente', () async {
    await expectLater(
      repositorio.inserir(
        HistoricoStatus(
          ordemId: 999999,
          statusNovo: 'Aberta',
          dataAlteracao: DateTime.utc(2026, 11, 9, 8),
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(await repositorio.listar(), isEmpty);
  });

  test('Remove o historico quando a ordem e excluida', () async {
    final ordemId = await criarOrdem('OS-HIST-005');

    await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemId,
        statusNovo: 'Aberta',
        dataAlteracao: DateTime.utc(2026, 11, 9, 8),
      ),
    );

    await repositorio.inserir(
      HistoricoStatus(
        ordemId: ordemId,
        statusAnterior: 'Aberta',
        statusNovo: 'Atribuída',
        dataAlteracao: DateTime.utc(2026, 11, 9, 9),
      ),
    );

    expect(
      (await repositorio.listarPorOrdem(ordemId)).length,
      2,
    );

    final banco = await servico.database;

    await banco.delete(
      'ordens_servico',
      where: 'id = ?',
      whereArgs: [ordemId],
    );

    // Verifica o ON DELETE CASCADE do SQLite.
    expect(await repositorio.listarPorOrdem(ordemId), isEmpty);
  });
}
