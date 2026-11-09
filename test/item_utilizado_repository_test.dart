
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late ItemUtilizadoRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_item_utilizado_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'itens.db'),
    );

    repositorio = ItemUtilizadoRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  /// Prepara uma ordem válida para os testes dos itens.
  Future<int> criarOrdem() async {
    final banco = await servico.database;

    final clienteId = await banco.insert('clientes', {
      'nome': 'Cliente de teste',
      'documento': 'DOC-TESTE',
      'telefone': '71999990000',
    });

    final equipamentoId = await banco.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Notebook',
    });

    return banco.insert('ordens_servico', {
      'codigo': 'OS-ITEM-001',
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'descricao_problema': 'Equipamento nao liga',
      'prioridade': 'Normal',
      'status': 'Aberta',
      'data_abertura': DateTime.utc(2026, 11, 9).toIso8601String(),
      'valor_mao_obra_centavos': 0,
    });
  }

  test('Cadastra e consulta um item pelo ID', () async {
    final ordemId = await criarOrdem();

    final id = await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Memoria RAM',
        quantidade: 2,
        valorUnitarioCentavos: 15000,
      ),
    );

    expect(id, greaterThan(0));

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.id, id);
    expect(encontrado.ordemId, ordemId);
    expect(encontrado.descricao, 'Memoria RAM');
    expect(encontrado.quantidade, 2);
    expect(encontrado.valorUnitarioCentavos, 15000);
    expect(encontrado.subtotalCentavos, 30000);
  });

  test('Lista itens de uma ordem de servico', () async {
    final ordemId = await criarOrdem();

    await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Peca A',
        quantidade: 1,
        valorUnitarioCentavos: 1000,
      ),
    );

    await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Peca B',
        quantidade: 2,
        valorUnitarioCentavos: 2000,
      ),
    );

    final todos = await repositorio.listar();
    final itensDaOrdem = await repositorio.listarPorOrdem(ordemId);

    expect(todos.length, 2);
    expect(itensDaOrdem.length, 2);
    expect(itensDaOrdem[0].descricao, 'Peca A');
    expect(itensDaOrdem[1].descricao, 'Peca B');

    final ordemSemItens = await repositorio.listarPorOrdem(999999);

    expect(ordemSemItens, isEmpty);
  });

  test('Atualiza e exclui um item', () async {
    final ordemId = await criarOrdem();

    final id = await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Peca original',
        quantidade: 1,
        valorUnitarioCentavos: 5000,
      ),
    );

    final atualizados = await repositorio.atualizar(
      ItemUtilizado(
        id: id,
        ordemId: ordemId,
        descricao: 'Peca atualizada',
        quantidade: 3,
        valorUnitarioCentavos: 6000,
      ),
    );

    expect(atualizados, 1);

    final atualizado = await repositorio.buscarPorId(id);

    expect(atualizado, isNotNull);
    expect(atualizado!.descricao, 'Peca atualizada');
    expect(atualizado.quantidade, 3);
    expect(atualizado.subtotalCentavos, 18000);

    final excluidos = await repositorio.excluir(id);

    expect(excluidos, 1);
    expect(await repositorio.buscarPorId(id), isNull);
    expect(await repositorio.listarPorOrdem(ordemId), isEmpty);
  });

  test('Calcula corretamente o total dos materiais', () async {
    final ordemId = await criarOrdem();

    // Uma ordem sem itens deve ter total igual a zero.
    expect(await repositorio.calcularTotalCentavos(ordemId), 0);

    await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Material de consumo',
        quantidade: 2,
        valorUnitarioCentavos: 4500,
      ),
    );

    await repositorio.inserir(
      ItemUtilizado(
        ordemId: ordemId,
        descricao: 'Peca de reposicao',
        quantidade: 1,
        valorUnitarioCentavos: 12000,
      ),
    );

    // R$ 90,00 + R$ 120,00 = R$ 210,00.
    final total = await repositorio.calcularTotalCentavos(ordemId);

    expect(total, 21000);
  });

  test('Rejeita descricao vazia e valores invalidos', () async {
    final ordemId = await criarOrdem();

    await expectLater(
      repositorio.inserir(
        ItemUtilizado(
          ordemId: ordemId,
          descricao: '   ',
          quantidade: 1,
          valorUnitarioCentavos: 1000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      repositorio.inserir(
        ItemUtilizado(
          ordemId: ordemId,
          descricao: 'Quantidade invalida',
          quantidade: 0,
          valorUnitarioCentavos: 1000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    await expectLater(
      repositorio.inserir(
        ItemUtilizado(
          ordemId: ordemId,
          descricao: 'Valor invalido',
          quantidade: 1,
          valorUnitarioCentavos: -100,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede item vinculado a ordem inexistente', () async {
    await expectLater(
      repositorio.inserir(
        const ItemUtilizado(
          ordemId: 999999,
          descricao: 'Peca de teste',
          quantidade: 1,
          valorUnitarioCentavos: 1000,
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede atualizar item sem ID', () async {
    final ordemId = await criarOrdem();

    await expectLater(
      repositorio.atualizar(
        ItemUtilizado(
          ordemId: ordemId,
          descricao: 'Item sem ID',
          quantidade: 1,
          valorUnitarioCentavos: 1000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
