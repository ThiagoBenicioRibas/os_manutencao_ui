import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/repositories/cliente_repository.dart';
import 'package:os_manutencao_ui/repositories/equipamento_repository.dart';
import 'package:os_manutencao_ui/repositories/tecnico_repository.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/services/database_service.dart';
import 'package:os_manutencao_ui/services/dashboard_service.dart';
import 'package:os_manutencao_ui/screens/orders/orders_page.dart';

void main() {
  late Directory pasta;
  late DatabaseService banco;
  late ClienteController clientes;
  late EquipamentoController equipamentos;
  late TecnicoController tecnicos;
  late OrdemServicoController ordens;
  late ItemUtilizadoController itens;

  setUp(() async {
    pasta = await Directory.systemTemp.createTemp('auditoria_os_');
    banco = DatabaseService.forTesting('${pasta.path}/auditoria.db');
    clientes = ClienteController(repositorio: ClienteRepository(databaseService: banco));
    equipamentos = EquipamentoController(repositorio: EquipamentoRepository(databaseService: banco));
    tecnicos = TecnicoController(repositorio: TecnicoRepository(databaseService: banco));
    ordens = OrdemServicoController(repositorio: OrdemServicoRepository(databaseService: banco));
    itens = ItemUtilizadoController(repositorio: ItemUtilizadoRepository(databaseService: banco));
    final cliente = await clientes.cadastrar(const Cliente(nome: 'Oficina Aurora', documento: 'DEMO-1', telefone: '41999990001'));
    final equipamento = await equipamentos.cadastrar(Equipamento(clienteId: cliente, tipo: 'Notebook', modelo: 'Modelo Alfa'));
    final tecnico = await tecnicos.cadastrar(const Tecnico(nome: 'Ana Técnica', contato: '41999990002', especialidade: 'Informática', situacao: 'Ativo'));
    for (var n = 1; n <= 10; n++) {
      final id = await ordens.cadastrar(OrdemServico(
        codigo: 'DEMO-${n.toString().padLeft(2, '0')}', clienteId: cliente,
        equipamentoId: equipamento, tecnicoId: tecnico,
        descricaoProblema: 'Falha demonstrativa $n',
        prioridade: n == 1 ? 'Urgente' : 'Média', status: 'Aberta',
        dataAbertura: DateTime(2026, 1, 1), prazoPrevisto: DateTime(2026, 1, n == 1 ? 1 : 20),
        diagnostico: 'Componente defeituoso', solucao: 'Componente substituído',
        valorMaoObraCentavos: 10000,
      ));
      if (n >= 3 && n <= 9) await ordens.alterarStatus(ordemId: id, novoStatus: 'Atribuída');
      if (n >= 5 && n <= 9) await ordens.alterarStatus(ordemId: id, novoStatus: 'Em atendimento');
      if (n == 7) await ordens.alterarStatus(ordemId: id, novoStatus: 'Aguardando peça');
      if (n == 8 || n == 9) await ordens.alterarStatus(ordemId: id, novoStatus: 'Concluída');
      if (n == 10) await ordens.alterarStatus(ordemId: id, novoStatus: 'Cancelada');
      await itens.cadastrar(ItemUtilizado(ordemId: id, descricao: 'Peça', quantidade: 2, valorUnitarioCentavos: 2500));
    }
  });

  tearDown(() async {
    clientes.dispose(); equipamentos.dispose(); tecnicos.dispose(); ordens.dispose(); itens.dispose();
    await banco.close();
    await pasta.delete(recursive: true);
  });

  test('Dez OS integram controladores, regras, financeiro e SQLite reaberto', () async {
    final primeira = ordens.ordens.singleWhere((o) => o.codigo == 'DEMO-01');
    await expectLater(clientes.excluir(primeira.clienteId), throwsA(anything));
    await expectLater(equipamentos.excluir(primeira.equipamentoId), throwsA(anything));
    await expectLater(tecnicos.excluir(primeira.tecnicoId!), throwsA(anything));
    await expectLater(ordens.alterarStatus(ordemId: primeira.id!, novoStatus: 'Concluída'), throwsStateError);
    await expectLater(ordens.cadastrar(primeira), throwsA(anything));
    await ordens.atualizar(OrdemServico.fromMap({...primeira.toMap(), 'descricao_problema': 'Descrição revisada'}));
    await banco.close();
    final reaberto = DatabaseService.forTesting('${pasta.path}/auditoria.db');
    try {
      final persistidas = await OrdemServicoRepository(databaseService: reaberto).listar();
      final materiais = await ItemUtilizadoRepository(databaseService: reaberto).listar();
      final resumo = const DashboardService().calcular(ordens: persistidas, itens: materiais, referencia: DateTime(2026, 1, 10));
      expect(resumo.total, 10);
      expect(resumo.porStatus, {'Aberta': 2, 'Atribuída': 2, 'Em atendimento': 2, 'Aguardando peça': 1, 'Concluída': 2, 'Cancelada': 1});
      expect(resumo.urgentes, 1);
      expect(resumo.atrasadas, 1);
      expect(resumo.valorRegistradoCentavos, 150000);
      expect(persistidas.singleWhere((o) => o.id == primeira.id).descricaoProblema, 'Descrição revisada');
      final db = await reaberto.database;
      expect((await db.query('historico_status')).length, 16);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
      expect((await db.rawQuery('PRAGMA integrity_check')).single.values.single, 'ok');
      await OrdemServicoRepository(databaseService: reaberto).excluir(primeira.id!);
      expect(await ItemUtilizadoRepository(databaseService: reaberto).listarPorOrdem(primeira.id!), isEmpty);
      expect((await OrdemServicoRepository(databaseService: reaberto).listar()).length, 9);
    } finally {
      await reaberto.close();
    }
  });

  testWidgets('Lista real consulta SQLite e aplica buscas e filtros na UI', (tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<ClienteController>.value(value: clientes),
      ChangeNotifierProvider<EquipamentoController>.value(value: equipamentos),
      ChangeNotifierProvider<TecnicoController>.value(value: tecnicos),
      ChangeNotifierProvider<OrdemServicoController>.value(value: ordens),
    ], child: const MaterialApp(home: Scaffold(body: OrdersPage()))));
    await tester.runAsync(() async {
      for (var i = 0; i < 100; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (!ordens.carregando && !clientes.carregando && !equipamentos.carregando && !tecnicos.carregando) break;
      }
    });
    await tester.pumpAndSettle();
    expect(find.text('10 ordens de serviço encontradas'), findsOneWidget);
    for (final termo in ['DEMO-01', 'Oficina Aurora', 'Modelo Alfa', 'Ana Técnica', 'inexistente']) {
      await tester.enterText(find.byType(TextField).first, termo);
      await tester.pumpAndSettle();
      final quantidade = termo == 'DEMO-01' ? 1 : termo == 'inexistente' ? 0 : 10;
      expect(find.text('$quantidade ordens de serviço encontradas'), findsOneWidget);
    }
    await tester.enterText(find.byType(TextField).first, '');
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Concluída').last);
    await tester.pumpAndSettle();
    expect(find.text('2 ordens de serviço encontradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
