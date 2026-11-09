
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/repositories/cliente_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late ClienteRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_cliente_repository_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'clientes.db'),
    );

    repositorio = ClienteRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  test('Cadastra e consulta um cliente pelo ID', () async {
    const cliente = Cliente(
      nome: 'Maria Oliveira',
      documento: 'DOC-001',
      telefone: '71999990000',
      email: 'maria@exemplo.com',
      endereco: 'Salvador - BA',
    );

    final id = await repositorio.inserir(cliente);

    expect(id, greaterThan(0));

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.id, id);
    expect(encontrado.nome, 'Maria Oliveira');
    expect(encontrado.documento, 'DOC-001');
    expect(encontrado.telefone, '71999990000');
    expect(encontrado.email, 'maria@exemplo.com');
    expect(encontrado.endereco, 'Salvador - BA');
  });

  test('Lista clientes em ordem alfabetica', () async {
    await repositorio.inserir(
      const Cliente(
        nome: 'Zelia',
        documento: 'DOC-002',
        telefone: '111111111',
      ),
    );

    await repositorio.inserir(
      const Cliente(
        nome: 'Ana',
        documento: 'DOC-003',
        telefone: '222222222',
      ),
    );

    final clientes = await repositorio.listar();

    expect(clientes.length, 2);
    expect(clientes[0].nome, 'Ana');
    expect(clientes[1].nome, 'Zelia');

    // E-mail e endereco podem permanecer vazios.
    expect(clientes[0].email, isNull);
    expect(clientes[0].endereco, isNull);
  });

  test('Atualiza e exclui um cliente', () async {
    final id = await repositorio.inserir(
      const Cliente(
        nome: 'Cliente Original',
        documento: 'DOC-004',
        telefone: '333333333',
      ),
    );

    final quantidadeAtualizada = await repositorio.atualizar(
      Cliente(
        id: id,
        nome: 'Cliente Atualizado',
        documento: 'DOC-004',
        telefone: '444444444',
      ),
    );

    expect(quantidadeAtualizada, 1);

    final atualizado = await repositorio.buscarPorId(id);

    expect(atualizado, isNotNull);
    expect(atualizado!.nome, 'Cliente Atualizado');
    expect(atualizado.telefone, '444444444');

    final quantidadeExcluida = await repositorio.excluir(id);

    expect(quantidadeExcluida, 1);

    final excluido = await repositorio.buscarPorId(id);

    expect(excluido, isNull);
    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede atualizar cliente sem ID', () async {
    await expectLater(
      repositorio.atualizar(
        const Cliente(
          nome: 'Cliente Sem ID',
          documento: 'DOC-005',
          telefone: '555555555',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
