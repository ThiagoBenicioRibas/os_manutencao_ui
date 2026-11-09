
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/repositories/tecnico_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late TecnicoRepository repositorio;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_tecnico_repository_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'tecnicos.db'),
    );

    repositorio = TecnicoRepository(
      databaseService: servico,
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  test('Cadastra e consulta um técnico pelo ID', () async {
    const tecnico = Tecnico(
      nome: 'Carlos Oliveira',
      contato: '71999990000',
      especialidade: 'Informática',
      situacao: 'Ativo',
    );

    final id = await repositorio.inserir(tecnico);

    expect(id, greaterThan(0));

    final encontrado = await repositorio.buscarPorId(id);

    expect(encontrado, isNotNull);
    expect(encontrado!.id, id);
    expect(encontrado.nome, 'Carlos Oliveira');
    expect(encontrado.contato, '71999990000');
    expect(encontrado.especialidade, 'Informática');
    expect(encontrado.situacao, 'Ativo');
  });

  test('Lista técnicos em ordem alfabética', () async {
    await repositorio.inserir(
      const Tecnico(
        nome: 'Zeca',
        contato: '111111111',
        especialidade: 'Elétrica',
        situacao: 'Ativo',
      ),
    );

    await repositorio.inserir(
      const Tecnico(
        nome: 'Ana',
        contato: '222222222',
        especialidade: 'Climatização',
        situacao: 'Ativo',
      ),
    );

    final tecnicos = await repositorio.listar();

    expect(tecnicos.length, 2);
    expect(tecnicos[0].nome, 'Ana');
    expect(tecnicos[1].nome, 'Zeca');
  });

  test('Atualiza e exclui um técnico', () async {
    final id = await repositorio.inserir(
      const Tecnico(
        nome: 'Técnico Original',
        contato: '333333333',
        especialidade: 'Informática',
        situacao: 'Ativo',
      ),
    );

    final quantidadeAtualizada = await repositorio.atualizar(
      Tecnico(
        id: id,
        nome: 'Técnico Atualizado',
        contato: '444444444',
        especialidade: 'Redes',
        situacao: 'Inativo',
      ),
    );

    expect(quantidadeAtualizada, 1);

    final atualizado = await repositorio.buscarPorId(id);

    expect(atualizado, isNotNull);
    expect(atualizado!.nome, 'Técnico Atualizado');
    expect(atualizado.contato, '444444444');
    expect(atualizado.especialidade, 'Redes');
    expect(atualizado.situacao, 'Inativo');

    final quantidadeExcluida = await repositorio.excluir(id);

    expect(quantidadeExcluida, 1);
    expect(await repositorio.buscarPorId(id), isNull);
    expect(await repositorio.listar(), isEmpty);
  });

  test('Impede atualizar técnico sem ID', () async {
    await expectLater(
      repositorio.atualizar(
        const Tecnico(
          nome: 'Técnico Sem ID',
          contato: '555555555',
          especialidade: 'Elétrica',
          situacao: 'Ativo',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
