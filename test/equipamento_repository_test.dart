
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/repositories/equipamento_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late EquipamentoRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_equipamento_repository_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'equipamentos.db'),
    );

    repositorio = EquipamentoRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  /// Cria um cliente válido para os testes de equipamento.
  Future<int> criarCliente(String nome) async {
    final banco = await servico.database;

    return banco.insert('clientes', {
      'nome': nome,
      'documento': 'DOC-$nome',
      'telefone': '71999990000',
    });
  }

  test('Cadastra e consulta um equipamento pelo ID', () async {
    final clienteId = await criarCliente('Cliente A');

    final equipamento = Equipamento(
      clienteId: clienteId,
      tipo: 'Notebook',
      marca: 'Dell',
      modelo: 'Latitude',
      numeroSerie: 'SERIE-001',
      patrimonio: 'PAT-001',
      observacoes: 'Equipamento de teste',
    );

    final id = await repositorio.inserir(equipamento);

    expect(id, greaterThan(0));

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.id, id);
    expect(encontrado.clienteId, clienteId);
    expect(encontrado.tipo, 'Notebook');
    expect(encontrado.marca, 'Dell');
    expect(encontrado.modelo, 'Latitude');
    expect(encontrado.numeroSerie, 'SERIE-001');
    expect(encontrado.patrimonio, 'PAT-001');
    expect(encontrado.observacoes, 'Equipamento de teste');
  });

  test('Lista equipamentos e filtra pelo cliente', () async {
    final clienteA = await criarCliente('Cliente A');
    final clienteB = await criarCliente('Cliente B');

    await repositorio.inserir(
      Equipamento(
        clienteId: clienteA,
        tipo: 'Notebook',
      ),
    );

    await repositorio.inserir(
      Equipamento(
        clienteId: clienteB,
        tipo: 'Impressora',
      ),
    );

    await repositorio.inserir(
      Equipamento(
        clienteId: clienteA,
        tipo: 'Ar-condicionado',
      ),
    );

    final todos = await repositorio.listar();

    expect(todos.length, 3);
    expect(todos.first.tipo, 'Ar-condicionado');

    final equipamentosA = await repositorio.listarPorCliente(
      clienteA,
    );

    expect(equipamentosA.length, 2);
    expect(equipamentosA[0].tipo, 'Ar-condicionado');
    expect(equipamentosA[1].tipo, 'Notebook');

    for (final equipamento in equipamentosA) {
      expect(equipamento.clienteId, clienteA);
    }

    final equipamentosB = await repositorio.listarPorCliente(
      clienteB,
    );

    expect(equipamentosB.length, 1);
    expect(equipamentosB.first.tipo, 'Impressora');
  });

  test('Atualiza e exclui um equipamento', () async {
    final clienteId = await criarCliente('Cliente A');

    final id = await repositorio.inserir(
      Equipamento(
        clienteId: clienteId,
        tipo: 'Computador',
        marca: 'Marca antiga',
      ),
    );

    final quantidadeAtualizada = await repositorio.atualizar(
      Equipamento(
        id: id,
        clienteId: clienteId,
        tipo: 'Computador',
        marca: 'Marca atualizada',
        modelo: 'Modelo novo',
      ),
    );

    expect(quantidadeAtualizada, 1);

    final atualizado = await repositorio.buscarPorId(id);

    expect(atualizado, isNotNull);
    expect(atualizado!.marca, 'Marca atualizada');
    expect(atualizado.modelo, 'Modelo novo');

    final quantidadeExcluida = await repositorio.excluir(id);

    expect(quantidadeExcluida, 1);
    expect(await repositorio.buscarPorId(id), isNull);
    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede cadastrar equipamento sem cliente válido', () async {
    await expectLater(
      repositorio.inserir(
        const Equipamento(
          clienteId: 999999,
          tipo: 'Notebook',
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede atualizar equipamento sem ID', () async {
    final clienteId = await criarCliente('Cliente A');

    await expectLater(
      repositorio.atualizar(
        Equipamento(
          clienteId: clienteId,
          tipo: 'Impressora',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
