import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late OrdemServicoRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_ordem_servico_repository_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'ordens.db'),
    );

    repositorio = OrdemServicoRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  Future<int> criarCliente(String nome) async {
    final banco = await servico.database;

    return banco.insert('clientes', {
      'nome': nome,
      'documento': 'DOC-$nome',
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

  Future<int> criarTecnico() async {
    final banco = await servico.database;

    return banco.insert('tecnicos', {
      'nome': 'Tecnico de teste',
      'contato': '71988880000',
      'especialidade': 'Informatica',
      'situacao': 'Ativo',
    });
  }

  OrdemServico criarOrdem({
    required String codigo,
    required int clienteId,
    required int equipamentoId,
    int? tecnicoId,
    int? id,
    String status = 'Aberta',
  }) {
    return OrdemServico(
      id: id,
      codigo: codigo,
      clienteId: clienteId,
      equipamentoId: equipamentoId,
      tecnicoId: tecnicoId,
      descricaoProblema: 'Equipamento nao liga',
      prioridade: 'Normal',
      status: status,
      dataAbertura: DateTime.utc(2026, 11, 9, 10),
      valorMaoObraCentavos: 5000,
    );
  }

  test('Cadastra e consulta uma ordem pelo ID', () async {
    final clienteId = await criarCliente('Cliente A');
    final equipamentoId = await criarEquipamento(clienteId);
    final tecnicoId = await criarTecnico();

    final ordem = criarOrdem(
      codigo: 'OS-TESTE-001',
      clienteId: clienteId,
      equipamentoId: equipamentoId,
      tecnicoId: tecnicoId,
    );

    final id = await repositorio.inserir(ordem);

    expect(id, greaterThan(0));

    final encontrada = await repositorio.buscarPorId(id);

    expect(encontrada, isNotNull);
    expect(encontrada!.id, id);
    expect(encontrada.codigo, 'OS-TESTE-001');
    expect(encontrada.clienteId, clienteId);
    expect(encontrada.equipamentoId, equipamentoId);
    expect(encontrada.tecnicoId, tecnicoId);
    expect(encontrada.status, 'Aberta');
    expect(encontrada.prioridade, 'Normal');
    expect(encontrada.valorMaoObraCentavos, 5000);
  });

  test('Lista ordens e filtra por cliente e tecnico', () async {
    final clienteA = await criarCliente('Cliente A');
    final clienteB = await criarCliente('Cliente B');

    final equipamentoA = await criarEquipamento(clienteA);
    final equipamentoB = await criarEquipamento(clienteB);

    final tecnicoId = await criarTecnico();

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-TESTE-002',
        clienteId: clienteA,
        equipamentoId: equipamentoA,
        tecnicoId: tecnicoId,
      ),
    );

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-TESTE-003',
        clienteId: clienteB,
        equipamentoId: equipamentoB,
      ),
    );

    await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-TESTE-004',
        clienteId: clienteA,
        equipamentoId: equipamentoA,
        tecnicoId: tecnicoId,
      ),
    );

    final todas = await repositorio.listar();
    expect(todas.length, 3);

    final ordensClienteA = await repositorio.listarPorCliente(
      clienteA,
    );

    expect(ordensClienteA.length, 2);

    for (final ordem in ordensClienteA) {
      expect(ordem.clienteId, clienteA);
    }

    final ordensTecnico = await repositorio.listarPorTecnico(
      tecnicoId,
    );

    expect(ordensTecnico.length, 2);

    for (final ordem in ordensTecnico) {
      expect(ordem.tecnicoId, tecnicoId);
    }
  });

  test('Impede OS com equipamento de outro cliente', () async {
    final clienteA = await criarCliente('Cliente A');
    final clienteB = await criarCliente('Cliente B');

    final equipamentoB = await criarEquipamento(clienteB);

    await expectLater(
      repositorio.inserir(
        criarOrdem(
          codigo: 'OS-TESTE-005',
          clienteId: clienteA,
          equipamentoId: equipamentoB,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await repositorio.listar(), isEmpty);
  });

  test('Atualiza e exclui uma OS com seus itens', () async {
    final clienteId = await criarCliente('Cliente A');
    final equipamentoId = await criarEquipamento(clienteId);

    final id = await repositorio.inserir(
      criarOrdem(
        codigo: 'OS-TESTE-006',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
      ),
    );

    final atualizados = await repositorio.atualizar(
      criarOrdem(
        id: id,
        codigo: 'OS-TESTE-006',
        clienteId: clienteId,
        equipamentoId: equipamentoId,
        status: 'Aberta',
      ),
    );

    expect(atualizados, 1);

    final atualizada = await repositorio.buscarPorId(id);

    expect(atualizada, isNotNull);
    expect(atualizada!.status, 'Aberta');

    final banco = await servico.database;

    await banco.insert('itens_utilizados', {
      'ordem_id': id,
      'descricao': 'Peca de teste',
      'quantidade': 2,
      'valor_unitario_centavos': 1500,
    });

    final excluidos = await repositorio.excluir(id);

    expect(excluidos, 1);
    expect(await repositorio.buscarPorId(id), isNull);

    final itensRestantes = await banco.query(
      'itens_utilizados',
      where: 'ordem_id = ?',
      whereArgs: [id],
    );

    expect(itensRestantes, isEmpty);
  });

  test('Impede atualizar uma OS sem ID', () async {
    final clienteId = await criarCliente('Cliente A');
    final equipamentoId = await criarEquipamento(clienteId);

    await expectLater(
      repositorio.atualizar(
        criarOrdem(
          codigo: 'OS-TESTE-007',
          clienteId: clienteId,
          equipamentoId: equipamentoId,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
  test('Rejeita status alterado e formulário antigo sem modificar histórico',
      () async {
    final cliente = await criarCliente('Regressão');
    final equipamento = await criarEquipamento(cliente);
    final tecnico = await criarTecnico();
    final id = await repositorio.inserir(criarOrdem(
        codigo: 'REG-1',
        clienteId: cliente,
        equipamentoId: equipamento,
        tecnicoId: tecnico));
    final antiga = (await repositorio.buscarPorId(id))!;
    await repositorio.alterarStatus(ordemId: id, novoStatus: 'Atribuída');
    final banco = await servico.database;
    final antes = await banco.query('historico_status');
    for (final status in ['Aberta', 'Concluída']) {
      await expectLater(
          repositorio.atualizar(
              OrdemServico.fromMap(antiga.toMap()..['status'] = status)),
          throwsStateError);
    }
    expect((await repositorio.buscarPorId(id))!.status, 'Atribuída');
    expect(await banco.query('historico_status'), antes);
  });

  for (final status in [
    'Atribuída',
    'Em atendimento',
    'Aguardando peça',
    'Concluída'
  ]) {
    test('Não remove técnico exigido em $status', () async {
      final cliente = await criarCliente('Regressão');
      final equipamento = await criarEquipamento(cliente);
      final tecnico = await criarTecnico();
      final id = await repositorio.inserir(criarOrdem(
          codigo: 'REG-2',
          clienteId: cliente,
          equipamentoId: equipamento,
          tecnicoId: tecnico,
          status: status));
      final antes = (await repositorio.buscarPorId(id))!;
      final dados = antes.toMap()..['tecnico_id'] = null;
      await expectLater(
          repositorio.atualizar(OrdemServico.fromMap(dados)), throwsStateError);
      expect((await repositorio.buscarPorId(id))!.toMap(), antes.toMap());
    });
  }

  test(
      'Conclusão mantém data e histórico; diagnóstico e solução não podem sumir',
      () async {
    final cliente = await criarCliente('Regressão');
    final equipamento = await criarEquipamento(cliente);
    final tecnico = await criarTecnico();
    final base = criarOrdem(
        codigo: 'REG-3',
        clienteId: cliente,
        equipamentoId: equipamento,
        tecnicoId: tecnico);
    final id = await repositorio.inserir(OrdemServico.fromMap(base.toMap()
      ..['diagnostico'] = 'Falha identificada'
      ..['solucao'] = 'Peça substituída'));
    await repositorio.alterarStatus(ordemId: id, novoStatus: 'Em atendimento');
    await repositorio.alterarStatus(ordemId: id, novoStatus: 'Concluída');
    final antes = (await repositorio.buscarPorId(id))!;
    final banco = await servico.database;
    final historico = await banco.query('historico_status');
    for (final campo in ['diagnostico', 'solucao']) {
      for (final valor in [null, '   ']) {
        await expectLater(
            repositorio.atualizar(
                OrdemServico.fromMap(antes.toMap()..[campo] = valor)),
            throwsStateError);
        expect((await repositorio.buscarPorId(id))!.toMap(), antes.toMap());
      }
    }
    for (final data in [null, DateTime(2000).toIso8601String()]) {
      expect(
          await repositorio.atualizar(OrdemServico.fromMap(antes.toMap()
            ..['data_conclusao'] = data
            ..['valor_mao_obra_centavos'] = 6000)),
          1);
      final depois = (await repositorio.buscarPorId(id))!;
      expect(depois.dataConclusao, antes.dataConclusao);
      expect(depois.status, 'Concluída');
      expect(depois.valorMaoObraCentavos, 6000);
      expect(await banco.query('historico_status'), historico);
    }
  });

  test('Edição não cria data de conclusão e rejeita vínculo inválido',
      () async {
    final cliente = await criarCliente('Regressão');
    final outro = await criarCliente('Outro');
    final equipamento = await criarEquipamento(cliente);
    final id = await repositorio.inserir(criarOrdem(
        codigo: 'REG-4', clienteId: cliente, equipamentoId: equipamento));
    final antes = (await repositorio.buscarPorId(id))!;
    await repositorio.atualizar(OrdemServico.fromMap(
        antes.toMap()..['data_conclusao'] = DateTime.now().toIso8601String()));
    expect((await repositorio.buscarPorId(id))!.dataConclusao, isNull);
    await expectLater(
        repositorio.atualizar(
            OrdemServico.fromMap(antes.toMap()..['cliente_id'] = outro)),
        throwsArgumentError);
    expect((await repositorio.buscarPorId(id))!.toMap(), antes.toMap());
    await expectLater(
        repositorio
            .atualizar(OrdemServico.fromMap(antes.toMap()..['id'] = 99999)),
        throwsStateError);
  });
}
