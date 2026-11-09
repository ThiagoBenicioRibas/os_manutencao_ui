
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/historico_status_controller.dart';
import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/repositories/historico_status_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late HistoricoStatusRepository repositorio;
  late HistoricoStatusController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_historico_status_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'historico.db'),
    );

    repositorio = HistoricoStatusRepository(
      databaseService: servico,
    );

    controlador = HistoricoStatusController(
      repositorio: repositorio,
    );
  });

  tearDown(() async {
    controlador.dispose();
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  // Cria uma ordem de serviço válida no banco temporário.
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
      'descricao_problema': 'Equipamento não liga',
      'prioridade': 'Normal',
      'status': 'Aberta',
      'data_abertura': DateTime.utc(2026, 11, 9).toIso8601String(),
      'valor_mao_obra_centavos': 0,
    });
  }

  // Cria um evento de histórico para os testes.
  HistoricoStatus criarHistorico({
    required int ordemId,
    String? statusAnterior,
    required String statusNovo,
    String? observacao,
  }) {
    return HistoricoStatus(
      ordemId: ordemId,
      statusAnterior: statusAnterior,
      statusNovo: statusNovo,
      dataAlteracao: DateTime.utc(2026, 11, 9, 14, 30),
      observacao: observacao,
    );
  }

  test('Carrega históricos e notifica mudanças de estado', () async {
    final ordemId = await criarOrdem('OS-HIST-001');

    await repositorio.inserir(
      criarHistorico(
        ordemId: ordemId,
        statusNovo: 'Aberta',
        observacao: 'Abertura da ordem',
      ),
    );

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.historicos.length, 1);
    expect(controlador.historicos.first.statusNovo, 'Aberta');
    expect(controlador.historicos.first.ordemId, ordemId);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
    expect(controlador.ordemIdFiltro, isNull);
    expect(notificacoes, [true, false]);
  });

  test('Registra evento com os dados corretos', () async {
    final ordemId = await criarOrdem('OS-HIST-002');

    final id = await controlador.registrar(
      criarHistorico(
        ordemId: ordemId,
        statusAnterior: 'Aberta',
        statusNovo: 'Em atendimento',
        observacao: 'Técnico iniciou o atendimento',
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.historicos.length, 1);

    final evento = controlador.historicos.first;

    expect(evento.id, id);
    expect(evento.ordemId, ordemId);
    expect(evento.statusAnterior, 'Aberta');
    expect(evento.statusNovo, 'Em atendimento');
    expect(
      evento.observacao,
      'Técnico iniciou o atendimento',
    );

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.statusNovo, 'Em atendimento');
    expect(
      encontrado.dataAlteracao,
      DateTime.utc(2026, 11, 9, 14, 30),
    );

    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Filtra históricos por ordem e preserva o filtro', () async {
    final ordemA = await criarOrdem('OS-HIST-003');
    final ordemB = await criarOrdem('OS-HIST-004');

    await repositorio.inserir(
      criarHistorico(
        ordemId: ordemA,
        statusNovo: 'Aberta',
      ),
    );

    await repositorio.inserir(
      criarHistorico(
        ordemId: ordemB,
        statusNovo: 'Aberta',
      ),
    );

    await controlador.carregarPorOrdem(ordemA);

    expect(controlador.ordemIdFiltro, ordemA);
    expect(controlador.historicos.length, 1);
    expect(controlador.historicos.first.ordemId, ordemA);

    // Registra outro evento sem perder o filtro atual.
    await controlador.registrar(
      criarHistorico(
        ordemId: ordemA,
        statusAnterior: 'Aberta',
        statusNovo: 'Atribuída',
      ),
    );

    expect(controlador.ordemIdFiltro, ordemA);
    expect(controlador.historicos.length, 2);

    for (final historico in controlador.historicos) {
      expect(historico.ordemId, ordemA);
    }

    // Consulta apenas os eventos da segunda ordem.
    await controlador.carregarPorOrdem(ordemB);

    expect(controlador.ordemIdFiltro, ordemB);
    expect(controlador.historicos.length, 1);
    expect(controlador.historicos.first.ordemId, ordemB);

    // Remove o filtro.
    await controlador.carregar();

    expect(controlador.ordemIdFiltro, isNull);
    expect(controlador.historicos.length, 3);
  });

  test('Protege a lista de históricos contra alterações externas',
      () async {
    final ordemId = await criarOrdem('OS-HIST-005');

    await controlador.registrar(
      criarHistorico(
        ordemId: ordemId,
        statusNovo: 'Aberta',
      ),
    );

    expect(controlador.historicos.length, 1);

    // A interface pode consultar a lista,
    // mas não modificá-la diretamente.
    expect(
      () => controlador.historicos.clear(),
      throwsUnsupportedError,
    );

    expect(controlador.historicos.length, 1);

    final persistidos = await repositorio.listarPorOrdem(ordemId);

    expect(persistidos.length, 1);
  });

  test('Registra erro quando a ordem não existe', () async {
    await expectLater(
      controlador.registrar(
        criarHistorico(
          ordemId: 999999,
          statusAnterior: 'Aberta',
          statusNovo: 'Em atendimento',
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.historicos, isEmpty);

    final registrosPersistidos = await repositorio.listar();

    expect(registrosPersistidos, isEmpty);
  });
}
