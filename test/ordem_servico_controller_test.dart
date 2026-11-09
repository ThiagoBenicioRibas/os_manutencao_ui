
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late OrdemServicoRepository repositorio;
  late OrdemServicoController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_ordem_servico_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'ordens.db'),
    );

    repositorio = OrdemServicoRepository(
      databaseService: servico,
    );

    controlador = OrdemServicoController(
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

  Future<int> criarCliente(String documento) async {
    final banco = await servico.database;

    return banco.insert('clientes', {
      'nome': 'Cliente $documento',
      'documento': documento,
      'telefone': '71999990000',
    });
  }

  Future<int> criarEquipamento(int clienteId) async {
    final banco = await servico.database;

    return banco.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Notebook',
    });
  }

  Future<int> criarTecnico(String nome) async {
    final banco = await servico.database;

    return banco.insert('tecnicos', {
      'nome': nome,
      'contato': '71988880000',
      'especialidade': 'Informática',
      'situacao': 'Ativo',
    });
  }

  OrdemServico criarOrdem({
    required String codigo,
    required int clienteId,
    required int equipamentoId,
    int? tecnicoId,
    String status = 'Aberta',
  }) {
    return OrdemServico(
      codigo: codigo,
      clienteId: clienteId,
      equipamentoId: equipamentoId,
      tecnicoId: tecnicoId,
      descricaoProblema: 'Equipamento não liga',
      prioridade: 'Normal',
      status: status,
      dataAbertura: DateTime.utc(2026, 11, 9),
      valorMaoObraCentavos: 0,
    );
  }

  test('Carrega ordens e notifica mudanças de estado', () async {
    final clienteId = await criarCliente('DOC-001');
    final equipamentoId = await criarEquipamento(clienteId);

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-001',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
      ),
    );

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.ordens.length, 1);
    expect(controlador.ordens.first.codigo, 'OS-001');
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
    expect(controlador.clienteIdFiltro, isNull);
    expect(controlador.tecnicoIdFiltro, isNull);
    expect(notificacoes, [true, false]);
  });

  test('Cadastra, atualiza e exclui ordens', () async {
    final clienteId = await criarCliente('DOC-002');
    final equipamentoId = await criarEquipamento(clienteId);

    final id = await controlador.cadastrar(
      criarOrdem(
        codigo: 'OS-002',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.ordens.length, 1);
    expect(controlador.ordens.first.status, 'Aberta');

    // Cria a versão atualizada com o mesmo ID.
    // Não depende do método copyWith().
    final ordemAtualizada = OrdemServico(
      id: id,
      codigo: 'OS-002',
      clienteId: clienteId,
      equipamentoId: equipamentoId,
      descricaoProblema: 'Equipamento não liga',
      prioridade: 'Normal',
      status: 'Em atendimento',
      dataAbertura: DateTime.utc(2026, 11, 9),
      valorMaoObraCentavos: 0,
    );

    final atualizados = await controlador.atualizar(
      ordemAtualizada,
    );

    expect(atualizados, 1);
    expect(controlador.ordens.length, 1);
    expect(
      controlador.ordens.first.status,
      'Em atendimento',
    );

    final excluidos = await controlador.excluir(id);

    expect(excluidos, 1);
    expect(controlador.ordens, isEmpty);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Filtra ordens por cliente e preserva o filtro', () async {
    final clienteA = await criarCliente('DOC-003');
    final clienteB = await criarCliente('DOC-004');

    final equipamentoA = await criarEquipamento(clienteA);
    final equipamentoB = await criarEquipamento(clienteB);

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-003',
        clienteId: clienteA,
        equipamentoId: equipamentoA,
      ),
    );

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-004',
        clienteId: clienteB,
        equipamentoId: equipamentoB,
      ),
    );

    await controlador.carregarPorCliente(clienteA);

    expect(controlador.clienteIdFiltro, clienteA);
    expect(controlador.tecnicoIdFiltro, isNull);
    expect(controlador.ordens.length, 1);
    expect(controlador.ordens.first.codigo, 'OS-003');

    await controlador.cadastrar(
      criarOrdem(
        codigo: 'OS-005',
        clienteId: clienteA,
        equipamentoId: equipamentoA,
      ),
    );

    expect(controlador.clienteIdFiltro, clienteA);
    expect(controlador.ordens.length, 2);

    for (final ordem in controlador.ordens) {
      expect(ordem.clienteId, clienteA);
    }

    await controlador.carregar();

    expect(controlador.clienteIdFiltro, isNull);
    expect(controlador.ordens.length, 3);
  });

  test('Filtra ordens por técnico responsável', () async {
    final clienteId = await criarCliente('DOC-005');
    final equipamentoId = await criarEquipamento(clienteId);

    final tecnicoA = await criarTecnico('Técnico A');
    final tecnicoB = await criarTecnico('Técnico B');

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-006',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
        tecnicoId: tecnicoA,
      ),
    );

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-007',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
        tecnicoId: tecnicoB,
      ),
    );

    await controlador.carregarPorTecnico(tecnicoA);

    expect(controlador.tecnicoIdFiltro, tecnicoA);
    expect(controlador.clienteIdFiltro, isNull);
    expect(controlador.ordens.length, 1);
    expect(controlador.ordens.first.codigo, 'OS-006');

    await controlador.cadastrar(
      criarOrdem(
        codigo: 'OS-008',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
        tecnicoId: tecnicoA,
      ),
    );

    expect(controlador.tecnicoIdFiltro, tecnicoA);
    expect(controlador.ordens.length, 2);

    for (final ordem in controlador.ordens) {
      expect(ordem.tecnicoId, tecnicoA);
    }

    await controlador.carregarPorTecnico(tecnicoB);

    expect(controlador.tecnicoIdFiltro, tecnicoB);
    expect(controlador.ordens.length, 1);
    expect(controlador.ordens.first.codigo, 'OS-007');
  });

  test(
    'Registra erro quando equipamento não pertence ao cliente',
    () async {
      final clienteA = await criarCliente('DOC-006');
      final clienteB = await criarCliente('DOC-007');

      final equipamentoB = await criarEquipamento(clienteB);

      await expectLater(
        controlador.cadastrar(
          criarOrdem(
            codigo: 'OS-009',
            clienteId: clienteA,
            equipamentoId: equipamentoB,
          ),
        ),
        throwsA(anything),
      );

      expect(controlador.erro, isNotNull);
      expect(controlador.carregando, isFalse);
      expect(controlador.ordens, isEmpty);

      final ordensPersistidas = await repositorio.listar();
      expect(ordensPersistidas, isEmpty);
    },
  );
}
