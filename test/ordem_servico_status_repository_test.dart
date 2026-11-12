
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  group('Etapa 6 - Integração de status com SQLite', () {
    late Directory pastaTemporaria;
    late DatabaseService databaseService;
    late Database banco;
    late OrdemServicoRepository repositorio;

    late int clienteId;
    late int tecnicoId;
    late int equipamentoId;
    late int ordemId;

    Future<int> criarOrdem({
      required String codigo,
      String status = 'Aberta',
      int? tecnicoResponsavel,
      String? diagnostico,
      String? solucao,
    }) {
      return repositorio.inserir(
        OrdemServico(
          codigo: codigo,
          clienteId: clienteId,
          equipamentoId: equipamentoId,
          tecnicoId: tecnicoResponsavel,
          descricaoProblema: 'Notebook não liga.',
          prioridade: 'Média',
          status: status,
          dataAbertura: DateTime(2026, 11, 12),
          diagnostico: diagnostico,
          solucao: solucao,
        ),
      );
    }

    Future<List<Map<String, Object?>>> consultarHistorico(
      int id,
    ) {
      return banco.query(
        'historico_status',
        where: 'ordem_id = ?',
        whereArgs: [id],
        orderBy: 'id ASC',
      );
    }

    setUp(() async {
      // Cada teste utiliza seu próprio banco SQLite temporário.
      pastaTemporaria = await Directory.systemTemp.createTemp(
        'os_manutencao_status_',
      );

      final caminhoBanco = p.join(
        pastaTemporaria.path,
        'teste_status.db',
      );

      databaseService = DatabaseService.forTesting(caminhoBanco);
      banco = await databaseService.database;

      repositorio = OrdemServicoRepository(
        databaseService: databaseService,
      );

      // Prepara os registros necessários às chaves estrangeiras.
      clienteId = await banco.insert(
        'clientes',
        {
          'nome': 'Cliente de teste',
          'documento': '12345678900',
          'telefone': '71999999999',
        },
      );

      tecnicoId = await banco.insert(
        'tecnicos',
        {
          'nome': 'Técnico de teste',
          'contato': '71988888888',
          'especialidade': 'Manutenção de notebooks',
          'situacao': 'Ativo',
        },
      );

      equipamentoId = await banco.insert(
        'equipamentos',
        {
          'cliente_id': clienteId,
          'tipo': 'Notebook',
          'marca': 'Marca de teste',
          'modelo': 'Modelo de teste',
        },
      );

      // Cria uma OS inicial em situação Aberta.
      ordemId = await criarOrdem(
        codigo: 'OS-STATUS-001',
        tecnicoResponsavel: tecnicoId,
        diagnostico: 'Falha na alimentação elétrica.',
        solucao: 'Fonte reparada e equipamento testado.',
      );
    });

    tearDown(() async {
      // Fecha a conexão antes de remover o banco temporário.
      await databaseService.close();

      if (await pastaTemporaria.exists()) {
        await pastaTemporaria.delete(recursive: true);
      }
    });

    test('Altera status e registra histórico na mesma operação',
        () async {
      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Atribuída',
        observacao: 'Técnico designado para atendimento.',
      );

      final ordemAtualizada = await repositorio.buscarPorId(
        ordemId,
      );

      final historico = await consultarHistorico(ordemId);

      expect(ordemAtualizada, isNotNull);
      expect(ordemAtualizada!.status, 'Atribuída');

      expect(historico, hasLength(1));
      expect(historico.first['ordem_id'], ordemId);
      expect(historico.first['status_anterior'], 'Aberta');
      expect(historico.first['status_novo'], 'Atribuída');
      expect(
        historico.first['observacao'],
        'Técnico designado para atendimento.',
      );
      expect(historico.first['data_alteracao'], isNotNull);
    });

    test('Registra sucessivas mudanças na ordem correta', () async {
      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Atribuída',
      );

      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Em atendimento',
      );

      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Concluída',
      );

      final ordemAtualizada = await repositorio.buscarPorId(
        ordemId,
      );

      final historico = await consultarHistorico(ordemId);

      expect(ordemAtualizada, isNotNull);
      expect(ordemAtualizada!.status, 'Concluída');
      expect(ordemAtualizada.dataConclusao, isNotNull);

      expect(historico, hasLength(3));

      expect(historico[0]['status_anterior'], 'Aberta');
      expect(historico[0]['status_novo'], 'Atribuída');

      expect(historico[1]['status_anterior'], 'Atribuída');
      expect(historico[1]['status_novo'], 'Em atendimento');

      expect(
        historico[2]['status_anterior'],
        'Em atendimento',
      );
      expect(historico[2]['status_novo'], 'Concluída');
    });

    test('Transição proibida não altera a OS nem o histórico',
        () async {
      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemId,
          novoStatus: 'Concluída',
        ),
        throwsA(isA<StateError>()),
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemId,
      );

      final historico = await consultarHistorico(ordemId);

      expect(ordemAtual!.status, 'Aberta');
      expect(ordemAtual.dataConclusao, isNull);
      expect(historico, isEmpty);
    });

    test('Não atribui ordem sem técnico responsável', () async {
      final ordemSemTecnicoId = await criarOrdem(
        codigo: 'OS-STATUS-SEM-TECNICO',
      );

      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemSemTecnicoId,
          novoStatus: 'Atribuída',
        ),
        throwsA(isA<StateError>()),
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemSemTecnicoId,
      );

      final historico = await consultarHistorico(
        ordemSemTecnicoId,
      );

      expect(ordemAtual!.status, 'Aberta');
      expect(historico, isEmpty);
    });

    test('Não conclui atendimento sem diagnóstico', () async {
      final ordemSemDiagnosticoId = await criarOrdem(
        codigo: 'OS-STATUS-SEM-DIAGNOSTICO',
        status: 'Em atendimento',
        tecnicoResponsavel: tecnicoId,
        solucao: 'Equipamento reparado.',
      );

      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemSemDiagnosticoId,
          novoStatus: 'Concluída',
        ),
        throwsA(isA<StateError>()),
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemSemDiagnosticoId,
      );

      final historico = await consultarHistorico(
        ordemSemDiagnosticoId,
      );

      expect(ordemAtual!.status, 'Em atendimento');
      expect(ordemAtual.dataConclusao, isNull);
      expect(historico, isEmpty);
    });

    test('Não conclui atendimento sem solução', () async {
      final ordemSemSolucaoId = await criarOrdem(
        codigo: 'OS-STATUS-SEM-SOLUCAO',
        status: 'Em atendimento',
        tecnicoResponsavel: tecnicoId,
        diagnostico: 'Problema na fonte.',
      );

      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemSemSolucaoId,
          novoStatus: 'Concluída',
        ),
        throwsA(isA<StateError>()),
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemSemSolucaoId,
      );

      final historico = await consultarHistorico(
        ordemSemSolucaoId,
      );

      expect(ordemAtual!.status, 'Em atendimento');
      expect(ordemAtual.dataConclusao, isNull);
      expect(historico, isEmpty);
    });

    test('Não altera uma ordem que não existe', () async {
      const idInexistente = 999999;

      await expectLater(
        repositorio.alterarStatus(
          ordemId: idInexistente,
          novoStatus: 'Atribuída',
        ),
        throwsA(isA<StateError>()),
      );

      final historico = await banco.query('historico_status');

      expect(historico, isEmpty);
    });

    test('Permite cancelar uma ordem sem técnico', () async {
      final ordemSemTecnicoId = await criarOrdem(
        codigo: 'OS-STATUS-CANCELAMENTO',
      );

      await repositorio.alterarStatus(
        ordemId: ordemSemTecnicoId,
        novoStatus: 'Cancelada',
        observacao: 'Solicitação cancelada pelo cliente.',
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemSemTecnicoId,
      );

      final historico = await consultarHistorico(
        ordemSemTecnicoId,
      );

      expect(ordemAtual!.status, 'Cancelada');
      expect(historico, hasLength(1));
      expect(historico.first['status_anterior'], 'Aberta');
      expect(historico.first['status_novo'], 'Cancelada');
    });

    test('Impede novas mudanças após conclusão', () async {
      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Em atendimento',
      );

      await repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: 'Concluída',
      );

      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemId,
          novoStatus: 'Aberta',
        ),
        throwsA(isA<StateError>()),
      );

      final ordemAtual = await repositorio.buscarPorId(
        ordemId,
      );

      final historico = await consultarHistorico(ordemId);

      expect(ordemAtual!.status, 'Concluída');
      expect(historico, hasLength(2));
    });

    test('Desfaz atualização quando a gravação do histórico falha',
        () async {
      // Simula uma falha do SQLite especificamente na
      // inserção do histórico de status.
      await banco.execute('''
        CREATE TRIGGER bloquear_historico_teste
        BEFORE INSERT ON historico_status
        BEGIN
          SELECT RAISE(
            ABORT,
            'Falha simulada no histórico'
          );
        END
      ''');

      await expectLater(
        repositorio.alterarStatus(
          ordemId: ordemId,
          novoStatus: 'Atribuída',
        ),
        throwsA(isA<DatabaseException>()),
      );

      // A atualização de status aconteceu primeiro, mas deve
      // ter sido revertida pela transação.
      final ordemAtual = await repositorio.buscarPorId(
        ordemId,
      );

      final historico = await consultarHistorico(ordemId);

      expect(
        ordemAtual!.status,
        'Aberta',
        reason: 'O status deve voltar ao valor anterior.',
      );

      expect(
        historico,
        isEmpty,
        reason: 'A transação não pode gravar histórico parcial.',
      );
    });
  });
}
