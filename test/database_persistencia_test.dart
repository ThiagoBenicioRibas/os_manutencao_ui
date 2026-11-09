
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Mantem os dados apos fechar e reabrir o SQLite', () async {
    // Cria uma pasta temporaria exclusiva para este teste.
    final diretorio = await Directory.systemTemp.createTemp(
      'teste_persistencia_os_',
    );

    final caminhoBanco = p.join(
      diretorio.path,
      'persistencia.db',
    );

    var servico = DatabaseService.forTesting(caminhoBanco);

    try {
      // Abre o banco e cadastra um cliente.
      final banco = await servico.database;

      final clienteId = await banco.insert('clientes', {
        'nome': 'Cliente Persistente',
        'documento': 'TESTE-PERSISTENCIA',
        'telefone': '000000000',
      });

      expect(clienteId, greaterThan(0));

      // Fecha a conexao com o SQLite.
      await servico.close();

      // Cria outro servico para abrir o mesmo arquivo.
      servico = DatabaseService.forTesting(caminhoBanco);

      final bancoReaberto = await servico.database;

      // Consulta o cliente depois da reabertura.
      final clientes = await bancoReaberto.query(
        'clientes',
        where: 'id = ?',
        whereArgs: [clienteId],
      );

      // Confirma que o cadastro permaneceu salvo.
      expect(clientes.length, 1);
      expect(clientes.first['nome'], 'Cliente Persistente');
      expect(
        clientes.first['documento'],
        'TESTE-PERSISTENCIA',
      );

      // Confirma que as chaves estrangeiras continuam ativas.
      final configuracao = await bancoReaberto.rawQuery(
        'PRAGMA foreign_keys',
      );

      expect(configuracao.first['foreign_keys'], 1);
    } finally {
      // Fecha a conexao e remove somente os dados de teste.
      await servico.close();

      if (await diretorio.exists()) {
        await diretorio.delete(recursive: true);
      }
    }
  });
}
