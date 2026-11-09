
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/repositories/cliente_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late ClienteRepository repositorio;
  late ClienteController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_cliente_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'clientes.db'),
    );

    repositorio = ClienteRepository(
      databaseService: servico,
    );

    controlador = ClienteController(
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

  test('Carrega clientes e notifica mudanças de estado', () async {
    await repositorio.inserir(
      const Cliente(
        nome: 'Zelia',
        documento: 'DOC-001',
        telefone: '111111111',
      ),
    );

    await repositorio.inserir(
      const Cliente(
        nome: 'Ana',
        documento: 'DOC-002',
        telefone: '222222222',
      ),
    );

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.clientes.length, 2);
    expect(controlador.clientes[0].nome, 'Ana');
    expect(controlador.clientes[1].nome, 'Zelia');

    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);

    // O controlador informa o inicio e o fim do carregamento.
    expect(notificacoes, [true, false]);
  });

  test('Cadastra, atualiza e exclui clientes', () async {
    final id = await controlador.cadastrar(
      const Cliente(
        nome: 'Cliente Original',
        documento: 'DOC-003',
        telefone: '333333333',
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.clientes.length, 1);
    expect(controlador.clientes.first.nome, 'Cliente Original');

    final atualizados = await controlador.atualizar(
      Cliente(
        id: id,
        nome: 'Cliente Atualizado',
        documento: 'DOC-003',
        telefone: '444444444',
      ),
    );

    expect(atualizados, 1);
    expect(controlador.clientes.length, 1);
    expect(controlador.clientes.first.nome, 'Cliente Atualizado');
    expect(controlador.clientes.first.telefone, '444444444');

    final excluidos = await controlador.excluir(id);

    expect(excluidos, 1);
    expect(controlador.clientes, isEmpty);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Registra erro ao excluir cliente com equipamento', () async {
    final clienteId = await controlador.cadastrar(
      const Cliente(
        nome: 'Cliente com equipamento',
        documento: 'DOC-004',
        telefone: '555555555',
      ),
    );

    final banco = await servico.database;

    await banco.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Notebook',
    });

    // O SQLite deve impedir a exclusao do cliente.
    await expectLater(
      controlador.excluir(clienteId),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);

    // O cliente continua cadastrado.
    expect(controlador.clientes.length, 1);
    expect(controlador.clientes.first.id, clienteId);

    final encontrado = await repositorio.buscarPorId(clienteId);

    expect(encontrado, isNotNull);
  });

  test('Registra erro ao atualizar cliente sem ID', () async {
    await expectLater(
      controlador.atualizar(
        const Cliente(
          nome: 'Cliente sem ID',
          documento: 'DOC-005',
          telefone: '666666666',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.clientes, isEmpty);
  });
}
