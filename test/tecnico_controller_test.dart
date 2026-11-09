
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/repositories/tecnico_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;
  late TecnicoRepository repositorio;
  late TecnicoController controlador;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_tecnico_controller_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'tecnicos.db'),
    );

    repositorio = TecnicoRepository(
      databaseService: servico,
    );

    controlador = TecnicoController(
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

  test('Carrega técnicos e notifica mudanças de estado', () async {
    await repositorio.inserir(
      const Tecnico(
        nome: 'Zelia',
        contato: '111111111',
        especialidade: 'Informática',
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

    final notificacoes = <bool>[];

    controlador.addListener(() {
      notificacoes.add(controlador.carregando);
    });

    await controlador.carregar();

    expect(controlador.tecnicos.length, 2);
    expect(controlador.tecnicos[0].nome, 'Ana');
    expect(controlador.tecnicos[1].nome, 'Zelia');

    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
    expect(notificacoes, [true, false]);
  });

  test('Cadastra, atualiza e exclui técnicos', () async {
    final id = await controlador.cadastrar(
      const Tecnico(
        nome: 'Técnico Original',
        contato: '333333333',
        especialidade: 'Informática',
        situacao: 'Ativo',
      ),
    );

    expect(id, greaterThan(0));
    expect(controlador.tecnicos.length, 1);
    expect(controlador.tecnicos.first.nome, 'Técnico Original');

    final atualizados = await controlador.atualizar(
      Tecnico(
        id: id,
        nome: 'Técnico Atualizado',
        contato: '444444444',
        especialidade: 'Redes',
        situacao: 'Inativo',
      ),
    );

    expect(atualizados, 1);
    expect(controlador.tecnicos.length, 1);
    expect(controlador.tecnicos.first.nome, 'Técnico Atualizado');
    expect(controlador.tecnicos.first.contato, '444444444');
    expect(controlador.tecnicos.first.especialidade, 'Redes');
    expect(controlador.tecnicos.first.situacao, 'Inativo');

    final excluidos = await controlador.excluir(id);

    expect(excluidos, 1);
    expect(controlador.tecnicos, isEmpty);
    expect(controlador.carregando, isFalse);
    expect(controlador.erro, isNull);
  });

  test('Registra erro ao excluir técnico vinculado a OS', () async {
    final tecnicoId = await controlador.cadastrar(
      const Tecnico(
        nome: 'Técnico com OS',
        contato: '555555555',
        especialidade: 'Elétrica',
        situacao: 'Ativo',
      ),
    );

    final banco = await servico.database;

    final clienteId = await banco.insert('clientes', {
      'nome': 'Cliente de teste',
      'documento': 'DOC-TEC-001',
      'telefone': '71999990000',
    });

    final equipamentoId = await banco.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Computador',
    });

    await banco.insert('ordens_servico', {
      'codigo': 'OS-TEC-001',
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'tecnico_id': tecnicoId,
      'descricao_problema': 'Equipamento não liga',
      'prioridade': 'Normal',
      'status': 'Atribuída',
      'data_abertura': DateTime.utc(2026, 11, 9).toIso8601String(),
      'valor_mao_obra_centavos': 0,
    });

    await expectLater(
      controlador.excluir(tecnicoId),
      throwsA(isA<Exception>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);

    // A exclusão foi bloqueada: o técnico continua cadastrado.
    expect(controlador.tecnicos.length, 1);
    expect(controlador.tecnicos.first.id, tecnicoId);

    final encontrado = await repositorio.buscarPorId(tecnicoId);
    expect(encontrado, isNotNull);
  });

  test('Registra erro ao atualizar técnico sem ID', () async {
    await expectLater(
      controlador.atualizar(
        const Tecnico(
          nome: 'Técnico sem ID',
          contato: '666666666',
          especialidade: 'Informática',
          situacao: 'Ativo',
        ),
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(controlador.erro, isNotNull);
    expect(controlador.carregando, isFalse);
    expect(controlador.tecnicos, isEmpty);
  });
}
