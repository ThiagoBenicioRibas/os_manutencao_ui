
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/repositories/equipamento_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late EquipamentoRepository repositorio;
  late EquipamentoController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_equipamento_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'equipamentos.db'),
    );

    repositorio = EquipamentoRepository(
      databaseService: servico,
    );

    controlador = EquipamentoController(
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

  /// Cria um cliente válido para os testes.
  Future<int> criarCliente(String nome) async {
    final banco = await servico.database;

    return banco.insert('clientes', {
      'nome': nome,
      'documento': 'DOC-$nome',
      'telefone': '71999990000',
    });
  }

  test('Carrega equipamentos e notifica mudanças de estado', () async {
    final clienteId = await criarCliente('Cliente A');

    await repositorio.inserir(
      Equipamento(
        clienteId: clienteId,
        tipo: 'Notebook',
      ),
    );

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.equipamentos.length, 1);
    expect(controlador.equipamentos.first.tipo, 'Notebook');
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
    expect(controlador.clienteIdFiltro, isNull);
    expect(notificacoes, [true, false]);
  });

  test('Filtra equipamentos por cliente e preserva o filtro', () async {
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

    await controlador.carregarPorCliente(clienteA);

    expect(controlador.clienteIdFiltro, clienteA);
    expect(controlador.equipamentos.length, 1);
    expect(controlador.equipamentos.first.tipo, 'Notebook');

    // O novo equipamento deve aparecer no filtro atual.
    await controlador.cadastrar(
      Equipamento(
        clienteId: clienteA,
        tipo: 'Monitor',
      ),
    );

    expect(controlador.clienteIdFiltro, clienteA);
    expect(controlador.equipamentos.length, 2);

    for (final equipamento in controlador.equipamentos) {
      expect(equipamento.clienteId, clienteA);
    }

    // Remove o filtro e carrega todos os equipamentos.
    await controlador.carregar();

    expect(controlador.clienteIdFiltro, isNull);
    expect(controlador.equipamentos.length, 3);
  });

  test('Cadastra, atualiza e exclui equipamentos', () async {
    final clienteId = await criarCliente('Cliente A');

    final id = await controlador.cadastrar(
      Equipamento(
        clienteId: clienteId,
        tipo: 'Computador',
        marca: 'Marca original',
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.equipamentos.length, 1);
    expect(controlador.equipamentos.first.tipo, 'Computador');

    final atualizados = await controlador.atualizar(
      Equipamento(
        id: id,
        clienteId: clienteId,
        tipo: 'Computador',
        marca: 'Marca atualizada',
        modelo: 'Modelo novo',
      ),
    );

    expect(atualizados, 1);
    expect(controlador.equipamentos.length, 1);
    expect(
      controlador.equipamentos.first.marca,
      'Marca atualizada',
    );
    expect(controlador.equipamentos.first.modelo, 'Modelo novo');

    final excluidos = await controlador.excluir(id);

    expect(excluidos, 1);
    expect(controlador.equipamentos, isEmpty);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Registra erros em operações inválidas', () async {
    // Não permite cadastrar equipamento sem cliente existente.
    await expectLater(
      controlador.cadastrar(
        const Equipamento(
          clienteId: 999999,
          tipo: 'Notebook',
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.equipamentos, isEmpty);

    final clienteId = await criarCliente('Cliente A');

    // Não permite atualizar equipamento sem identificador.
    await expectLater(
      controlador.atualizar(
        Equipamento(
          clienteId: clienteId,
          tipo: 'Impressora',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
  });

  test('Impede excluir equipamento vinculado a uma OS', () async {
    final clienteId = await criarCliente('Cliente A');

    final equipamentoId = await controlador.cadastrar(
      Equipamento(
        clienteId: clienteId,
        tipo: 'Notebook',
      ),
    );

    final banco = await servico.database;

    await banco.insert('ordens_servico', {
      'codigo': 'OS-EQUIP-001',
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'descricao_problema': 'Equipamento nao liga',
      'prioridade': 'Normal',
      'status': 'Aberta',
      'data_abertura': DateTime.utc(2026, 11, 9).toIso8601String(),
      'valor_mao_obra_centavos': 0,
    });

    // O SQLite deve bloquear a exclusão do equipamento.
    await expectLater(
      controlador.excluir(equipamentoId),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);

    // O equipamento deve continuar cadastrado.
    expect(controlador.equipamentos.length, 1);
    expect(controlador.equipamentos.first.id, equipamentoId);

    final encontrado = await repositorio.buscarPorId(
      equipamentoId,
    );

    expect(encontrado, isNotNull);
  });
}
