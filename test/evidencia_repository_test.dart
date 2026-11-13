
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/evidencia.dart';
import 'package:os_manutencao_ui/repositories/evidencia_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Etapa 7 - Repositório de evidências SQLite', () {
    late Directory diretorioTemporario;
    late DatabaseService servico;
    late EvidenciaRepository repositorio;

    /// Cria uma ordem de serviço válida no banco temporário.
    Future<int> criarOrdem(String codigo) async {
      final banco = await servico.database;

      final clienteId = await banco.insert(
        'clientes',
        {
          'nome': 'Cliente de teste',
          'documento': 'DOC-$codigo',
          'telefone': '71999990000',
        },
      );

      final equipamentoId = await banco.insert(
        'equipamentos',
        {
          'cliente_id': clienteId,
          'tipo': 'Notebook',
        },
      );

      return banco.insert(
        'ordens_servico',
        {
          'codigo': codigo,
          'cliente_id': clienteId,
          'equipamento_id': equipamentoId,
          'descricao_problema': 'Equipamento não liga',
          'prioridade': 'Média',
          'status': 'Aberta',
          'data_abertura':
              DateTime.utc(2026, 11, 12).toIso8601String(),
          'valor_mao_obra_centavos': 0,
        },
      );
    }

    setUp(() async {
      // Um banco temporário diferente para cada teste.
      diretorioTemporario = await Directory.systemTemp.createTemp(
        'teste_evidencias_',
      );

      servico = DatabaseService.forTesting(
        p.join(
          diretorioTemporario.path,
          'evidencias.db',
        ),
      );

      repositorio = EvidenciaRepository(
        databaseService: servico,
      );
    });

    tearDown(() async {
      await servico.close();

      if (await diretorioTemporario.exists()) {
        await diretorioTemporario.delete(recursive: true);
      }
    });

    test('Converte o modelo para SQLite e recupera os dados', () {
      final data = DateTime.utc(2026, 11, 12, 10, 30);

      final evidencia = Evidencia(
        id: 5,
        ordemId: 2,
        caminhoArquivo: 'evidencias/foto_001.png',
        descricao: 'Fotografia do equipamento',
        tipo: 'image/png',
        dataRegistro: data,
      );

      final mapa = evidencia.toMap();
      final recuperada = Evidencia.fromMap(mapa);

      expect(mapa['id'], 5);
      expect(mapa['ordem_id'], 2);
      expect(
        mapa['caminho_arquivo'],
        'evidencias/foto_001.png',
      );

      expect(recuperada.id, 5);
      expect(recuperada.ordemId, 2);
      expect(
        recuperada.caminhoArquivo,
        'evidencias/foto_001.png',
      );
      expect(
        recuperada.descricao,
        'Fotografia do equipamento',
      );
      expect(recuperada.tipo, 'image/png');
      expect(
        recuperada.dataRegistro.isAtSameMomentAs(data),
        isTrue,
      );
    });

    test('Cadastra e consulta uma evidência pelo ID', () async {
      final ordemId = await criarOrdem('OS-EVID-001');
      final data = DateTime.utc(2026, 11, 12, 11, 15);

      final id = await repositorio.inserir(
        Evidencia(
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/foto_teste.jpg',
          descricao: 'Equipamento antes do reparo',
          tipo: 'image/jpeg',
          dataRegistro: data,
        ),
      );

      expect(id, greaterThan(0));

      final encontrada = await repositorio.buscarPorId(id);

      expect(encontrada, isNotNull);
      expect(encontrada!.id, id);
      expect(encontrada.ordemId, ordemId);
      expect(
        encontrada.caminhoArquivo,
        'evidencias/foto_teste.jpg',
      );
      expect(
        encontrada.descricao,
        'Equipamento antes do reparo',
      );
      expect(encontrada.tipo, 'image/jpeg');
      expect(
        encontrada.dataRegistro.isAtSameMomentAs(data),
        isTrue,
      );
    });

    test('Aceita descrição e tipo opcionais', () async {
      final ordemId = await criarOrdem('OS-EVID-002');

      final id = await repositorio.inserir(
        Evidencia(
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/imagem.png',
          dataRegistro: DateTime.utc(2026, 11, 12),
        ),
      );

      final encontrada = await repositorio.buscarPorId(id);

      expect(encontrada, isNotNull);
      expect(encontrada!.descricao, isNull);
      expect(encontrada.tipo, isNull);
      expect(encontrada.caminhoArquivo, isNotEmpty);
    });

    test('Lista somente as evidências da ordem selecionada',
        () async {
      final ordemA = await criarOrdem('OS-EVID-003');
      final ordemB = await criarOrdem('OS-EVID-004');

      await repositorio.inserir(
        Evidencia(
          ordemId: ordemA,
          caminhoArquivo: 'evidencias/primeira.jpg',
          dataRegistro: DateTime.utc(2026, 11, 12, 9),
        ),
      );

      await repositorio.inserir(
        Evidencia(
          ordemId: ordemA,
          caminhoArquivo: 'evidencias/segunda.jpg',
          dataRegistro: DateTime.utc(2026, 11, 12, 10),
        ),
      );

      await repositorio.inserir(
        Evidencia(
          ordemId: ordemB,
          caminhoArquivo: 'evidencias/outra_ordem.jpg',
          dataRegistro: DateTime.utc(2026, 11, 12, 11),
        ),
      );

      final todas = await repositorio.listar();
      final evidenciasA = await repositorio.listarPorOrdem(
        ordemA,
      );

      expect(todas, hasLength(3));
      expect(evidenciasA, hasLength(2));

      // A listagem apresenta primeiro a imagem mais recente.
      expect(
        evidenciasA[0].caminhoArquivo,
        'evidencias/segunda.jpg',
      );
      expect(
        evidenciasA[1].caminhoArquivo,
        'evidencias/primeira.jpg',
      );

      final inexistentes = await repositorio.listarPorOrdem(
        999999,
      );

      expect(inexistentes, isEmpty);
    });

    test('Atualiza os dados de uma evidência existente', () async {
      final ordemId = await criarOrdem('OS-EVID-005');
      final data = DateTime.utc(2026, 11, 12, 12);

      final id = await repositorio.inserir(
        Evidencia(
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/original.jpg',
          descricao: 'Descrição original',
          tipo: 'image/jpeg',
          dataRegistro: data,
        ),
      );

      final quantidadeAtualizada = await repositorio.atualizar(
        Evidencia(
          id: id,
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/original.jpg',
          descricao: 'Descrição atualizada',
          tipo: 'image/jpeg',
          dataRegistro: data,
        ),
      );

      expect(quantidadeAtualizada, 1);

      final atualizada = await repositorio.buscarPorId(id);

      expect(atualizada, isNotNull);
      expect(
        atualizada!.descricao,
        'Descrição atualizada',
      );
    });

    test('Exclui o registro de uma evidência', () async {
      final ordemId = await criarOrdem('OS-EVID-006');

      final id = await repositorio.inserir(
        Evidencia(
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/excluir.jpg',
          dataRegistro: DateTime.utc(2026, 11, 12),
        ),
      );

      final quantidadeExcluida = await repositorio.excluir(id);

      expect(quantidadeExcluida, 1);
      expect(await repositorio.buscarPorId(id), isNull);
      expect(
        await repositorio.listarPorOrdem(ordemId),
        isEmpty,
      );
    });

    test('Rejeita ordem inválida ou caminho vazio', () async {
      final ordemId = await criarOrdem('OS-EVID-007');

      await expectLater(
        repositorio.inserir(
          Evidencia(
            ordemId: 0,
            caminhoArquivo: 'evidencias/foto.jpg',
            dataRegistro: DateTime.utc(2026, 11, 12),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      await expectLater(
        repositorio.inserir(
          Evidencia(
            ordemId: ordemId,
            caminhoArquivo: '   ',
            dataRegistro: DateTime.utc(2026, 11, 12),
          ),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await repositorio.listar(), isEmpty);
    });

    test('Impede evidência vinculada a uma OS inexistente',
        () async {
      await expectLater(
        repositorio.inserir(
          Evidencia(
            ordemId: 999999,
            caminhoArquivo: 'evidencias/invalida.jpg',
            dataRegistro: DateTime.utc(2026, 11, 12),
          ),
        ),
        throwsA(isA<Exception>()),
      );

      expect(await repositorio.listar(), isEmpty);
    });

    test('Exclui evidências quando a OS é removida', () async {
      final ordemId = await criarOrdem('OS-EVID-008');

      final id = await repositorio.inserir(
        Evidencia(
          ordemId: ordemId,
          caminhoArquivo: 'evidencias/associada.jpg',
          dataRegistro: DateTime.utc(2026, 11, 12),
        ),
      );

      final banco = await servico.database;

      final ordensExcluidas = await banco.delete(
        'ordens_servico',
        where: 'id = ?',
        whereArgs: [ordemId],
      );

      expect(ordensExcluidas, 1);

      // A chave estrangeira utiliza ON DELETE CASCADE.
      expect(await repositorio.buscarPorId(id), isNull);
      expect(
        await repositorio.listarPorOrdem(ordemId),
        isEmpty,
      );
    });
  });
}
