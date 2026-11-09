
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory diretorioTemporario;
  late DatabaseService servico;

  setUp(() async {
    diretorioTemporario = await Directory.systemTemp.createTemp(
      'teste_os_manutencao_',
    );

    servico = DatabaseService.forTesting(
      p.join(diretorioTemporario.path, 'teste.db'),
    );
  });

  tearDown(() async {
    await servico.close();

    if (await diretorioTemporario.exists()) {
      await diretorioTemporario.delete(recursive: true);
    }
  });

  test('Cria as sete tabelas e ativa as chaves estrangeiras', () async {
    final db = await servico.database;

    final resultado = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
    ''');

    final tabelas = resultado
        .map((linha) => linha['name'] as String)
        .toSet();

    expect(
      tabelas,
      containsAll([
        'clientes',
        'tecnicos',
        'equipamentos',
        'ordens_servico',
        'itens_utilizados',
        'historico_status',
        'evidencias',
      ]),
    );

    expect(tabelas.length, 7);

    final configuracao = await db.rawQuery('PRAGMA foreign_keys');

    expect(configuracao.first['foreign_keys'], 1);
  });

  test('Impede equipamento vinculado a cliente inexistente', () async {
    final db = await servico.database;

    await expectLater(
      db.insert('equipamentos', {
        'cliente_id': 999999,
        'tipo': 'Computador',
      }),
      throwsA(isA<Exception>()),
    );

    final equipamentos = await db.query('equipamentos');

    expect(equipamentos, isEmpty);
  });

  test('Protege clientes e exclui itens junto com a ordem', () async {
    final db = await servico.database;

    final clienteId = await db.insert('clientes', {
      'nome': 'Cliente de teste',
      'documento': 'TESTE-001',
      'telefone': '000000000',
    });

    final equipamentoId = await db.insert('equipamentos', {
      'cliente_id': clienteId,
      'tipo': 'Notebook',
    });

    final ordemId = await db.insert('ordens_servico', {
      'codigo': 'OS-TESTE-001',
      'cliente_id': clienteId,
      'equipamento_id': equipamentoId,
      'descricao_problema': 'Equipamento não liga',
      'prioridade': 'Normal',
      'status': 'Aberta',
      'data_abertura': DateTime.now().toIso8601String(),
      'valor_mao_obra_centavos': 5000,
    });

    await db.insert('itens_utilizados', {
      'ordem_id': ordemId,
      'descricao': 'Peça de teste',
      'quantidade': 2,
      'valor_unitario_centavos': 1500,
    });

    // Impede excluir um cliente que possui registros vinculados.
    await expectLater(
      db.delete(
        'clientes',
        where: 'id = ?',
        whereArgs: [clienteId],
      ),
      throwsA(isA<Exception>()),
    );

    // Impede cadastrar itens com quantidade igual a zero.
    await expectLater(
      db.insert('itens_utilizados', {
        'ordem_id': ordemId,
        'descricao': 'Item inválido',
        'quantidade': 0,
        'valor_unitario_centavos': 100,
      }),
      throwsA(isA<Exception>()),
    );

    // Exclui a ordem de serviço.
    await db.delete(
      'ordens_servico',
      where: 'id = ?',
      whereArgs: [ordemId],
    );

    // Confere se seus itens foram excluídos automaticamente.
    final itensRestantes = await db.query(
      'itens_utilizados',
      where: 'ordem_id = ?',
      whereArgs: [ordemId],
    );

    expect(itensRestantes, isEmpty);

    // Confere se o cliente e o equipamento foram preservados.
    final clientesRestantes = await db.query('clientes');
    final equipamentosRestantes = await db.query('equipamentos');

    expect(clientesRestantes.length, 1);
    expect(equipamentosRestantes.length, 1);
  });
}
