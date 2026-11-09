
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late ItemUtilizadoRepository repositorio;
  late ItemUtilizadoController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_item_utilizado_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'itens.db'),
    );

    repositorio = ItemUtilizadoRepository(
      databaseService: servico,
    );

    controlador = ItemUtilizadoController(
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

  // Cria uma ordem de serviço válida para os testes.
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

  ItemUtilizado criarItem({
    int? id,
    required int ordemId,
    required String descricao,
    required int quantidade,
    required int valorUnitarioCentavos,
  }) {
    return ItemUtilizado(
      id: id,
      ordemId: ordemId,
      descricao: descricao,
      quantidade: quantidade,
      valorUnitarioCentavos: valorUnitarioCentavos,
    );
  }

  test('Carrega itens e notifica mudanças de estado', () async {
    final ordemId = await criarOrdem('OS-ITEM-001');

    await repositorio.inserir(
      criarItem(
        ordemId: ordemId,
        descricao: 'Memória RAM',
        quantidade: 2,
        valorUnitarioCentavos: 15000,
      ),
    );

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.itens.length, 1);
    expect(controlador.itens.first.descricao, 'Memória RAM');
    expect(controlador.totalCentavos, 30000);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
    expect(controlador.ordemIdFiltro, isNull);
    expect(notificacoes, [true, false]);
  });

  test('Cadastra, atualiza e exclui itens', () async {
    final ordemId = await criarOrdem('OS-ITEM-002');

    final id = await controlador.cadastrar(
      criarItem(
        ordemId: ordemId,
        descricao: 'Cabo HDMI',
        quantidade: 2,
        valorUnitarioCentavos: 2500,
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.itens.length, 1);
    expect(controlador.totalCentavos, 5000);

    final atualizados = await controlador.atualizar(
      criarItem(
        id: id,
        ordemId: ordemId,
        descricao: 'Cabo HDMI atualizado',
        quantidade: 3,
        valorUnitarioCentavos: 3000,
      ),
    );

    expect(atualizados, 1);
    expect(controlador.itens.length, 1);
    expect(
      controlador.itens.first.descricao,
      'Cabo HDMI atualizado',
    );
    expect(controlador.totalCentavos, 9000);

    final excluidos = await controlador.excluir(id);

    expect(excluidos, 1);
    expect(controlador.itens, isEmpty);
    expect(controlador.totalCentavos, 0);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Filtra itens por ordem e preserva o filtro', () async {
    final ordemA = await criarOrdem('OS-ITEM-003');
    final ordemB = await criarOrdem('OS-ITEM-004');

    await repositorio.inserir(
      criarItem(
        ordemId: ordemA,
        descricao: 'Fonte',
        quantidade: 1,
        valorUnitarioCentavos: 8000,
      ),
    );

    await repositorio.inserir(
      criarItem(
        ordemId: ordemB,
        descricao: 'Teclado',
        quantidade: 1,
        valorUnitarioCentavos: 5000,
      ),
    );

    await controlador.carregarPorOrdem(ordemA);

    expect(controlador.ordemIdFiltro, ordemA);
    expect(controlador.itens.length, 1);
    expect(controlador.itens.first.descricao, 'Fonte');
    expect(controlador.totalCentavos, 8000);

    // O novo item deve aparecer no filtro atual.
    await controlador.cadastrar(
      criarItem(
        ordemId: ordemA,
        descricao: 'Ventoinha',
        quantidade: 2,
        valorUnitarioCentavos: 1500,
      ),
    );

    expect(controlador.ordemIdFiltro, ordemA);
    expect(controlador.itens.length, 2);
    expect(controlador.totalCentavos, 11000);

    for (final item in controlador.itens) {
      expect(item.ordemId, ordemA);
    }

    // Remove o filtro e consulta todos os itens.
    await controlador.carregar();

    expect(controlador.ordemIdFiltro, isNull);
    expect(controlador.itens.length, 3);
    expect(controlador.totalCentavos, 16000);
  });

  test('Calcula o total dos materiais de uma ordem', () async {
    final ordemA = await criarOrdem('OS-ITEM-005');
    final ordemB = await criarOrdem('OS-ITEM-006');

    await repositorio.inserir(
      criarItem(
        ordemId: ordemA,
        descricao: 'Peça A',
        quantidade: 2,
        valorUnitarioCentavos: 2500,
      ),
    );

    await repositorio.inserir(
      criarItem(
        ordemId: ordemA,
        descricao: 'Peça B',
        quantidade: 3,
        valorUnitarioCentavos: 1000,
      ),
    );

    await repositorio.inserir(
      criarItem(
        ordemId: ordemB,
        descricao: 'Peça C',
        quantidade: 1,
        valorUnitarioCentavos: 9000,
      ),
    );

    final totalA = await controlador.calcularTotalPorOrdemCentavos(
      ordemA,
    );

    final totalB = await controlador.calcularTotalPorOrdemCentavos(
      ordemB,
    );

    expect(totalA, 8000);
    expect(totalB, 9000);

    await controlador.carregarPorOrdem(ordemA);

    expect(controlador.totalCentavos, totalA);
  });

  test('Registra erros em operações inválidas', () async {
    // A ordem 999999 não existe no banco.
    await expectLater(
      controlador.cadastrar(
        criarItem(
          ordemId: 999999,
          descricao: 'Peça inválida',
          quantidade: 1,
          valorUnitarioCentavos: 1000,
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.itens, isEmpty);

    final ordemId = await criarOrdem('OS-ITEM-007');

    // Uma atualização precisa identificar o registro.
    await expectLater(
      controlador.atualizar(
        criarItem(
          ordemId: ordemId,
          descricao: 'Item sem ID',
          quantidade: 1,
          valorUnitarioCentavos: 2000,
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.itens, isEmpty);
  });
}
