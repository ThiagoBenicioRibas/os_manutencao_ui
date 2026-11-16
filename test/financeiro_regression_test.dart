import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/controllers/historico_status_controller.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/screens/orders/order_details_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';

class ItensTeste extends ItemUtilizadoRepository {
  bool falhar = false;
  int gravacoes = 0;
  final pendentes = <int, Completer<List<ItemUtilizado>>>{};
  @override
  Future<List<ItemUtilizado>> listarPorOrdem(int ordemId) async {
    if (pendentes.containsKey(ordemId)) return pendentes[ordemId]!.future;
    if (falhar) throw Exception('SQLITE detalhe técnico privado');
    return [
      ItemUtilizado(
          ordemId: ordemId,
          descricao: 'Peça',
          quantidade: 2,
          valorUnitarioCentavos: 1500)
    ];
  }

  @override
  Future<int> inserir(ItemUtilizado item) async => ++gravacoes;
}

class ClientesTeste extends ClienteController {
  @override
  Future<void> carregar() async {}
}

class EquipamentosTeste extends EquipamentoController {
  @override
  Future<void> carregar() async {}
}

class TecnicosTeste extends TecnicoController {
  @override
  Future<void> carregar() async {}
}

class HistoricoTeste extends HistoricoStatusController {
  @override
  Future<void> carregarPorOrdem(int ordemId) async {}
}

Widget aplicativo(Widget pagina, ItemUtilizadoController itens) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ClienteController>(
            create: (_) => ClientesTeste()),
        ChangeNotifierProvider<EquipamentoController>(
            create: (_) => EquipamentosTeste()),
        ChangeNotifierProvider<TecnicoController>(
            create: (_) => TecnicosTeste()),
        ChangeNotifierProvider<HistoricoStatusController>(
            create: (_) => HistoricoTeste()),
        ChangeNotifierProvider<ItemUtilizadoController>.value(value: itens),
      ],
      child: MaterialApp(home: pagina),
    );

void main() {
  late ItensTeste repo;
  late ItemUtilizadoController controller;
  setUp(() {
    repo = ItensTeste();
    controller = ItemUtilizadoController(repositorio: repo);
  });
  tearDown(() => controller.dispose());

  test('Falha na mesma ou outra OS limpa valores e nova tentativa recupera',
      () async {
    for (final id in [1, 2]) {
      repo.falhar = false;
      await controller.carregarPorOrdem(1);
      expect(controller.totalCentavos, 3000);
      repo.falhar = true;
      await expectLater(controller.carregarPorOrdem(id), throwsException);
      expect(controller.itens, isEmpty);
      expect(controller.totalCentavos, 0);
      expect(controller.dadosDisponiveis, isFalse);
      expect(controller.erro, isNot(contains('SQLITE')));
      repo.falhar = false;
      await controller.carregarPorOrdem(id);
      expect(controller.dadosDisponiveis, isTrue);
      expect(controller.itens.single.ordemId, id);
    }
  });

  test('Resposta atrasada de outra OS não substitui a consulta atual',
      () async {
    repo.pendentes[1] = Completer<List<ItemUtilizado>>();
    final antiga = controller.carregarPorOrdem(1);
    await controller.carregarPorOrdem(2);
    repo.pendentes[1]!.complete([]);
    await antiga;
    expect(controller.ordemIdFiltro, 2);
    expect(controller.itens.single.ordemId, 2);
    expect(controller.totalCentavos, 3000);
  });

  test('Gravação confirmada com recarga falha não pede nova gravação',
      () async {
    await controller.carregarPorOrdem(1);
    repo.falhar = true;
    final id = await controller.cadastrar(const ItemUtilizado(
        ordemId: 1,
        descricao: 'Peça',
        quantidade: 1,
        valorUnitarioCentavos: 10));
    expect(id, 1);
    expect(repo.gravacoes, 1);
    expect(controller.erro, startsWith('Alteração salva'));
    expect(controller.dadosDisponiveis, isFalse);
    expect(controller.itens, isEmpty);
  });

  testWidgets('Resumo fica indisponível no erro e volta após nova tentativa',
      (tester) async {
    await controller.carregarPorOrdem(1);
    repo.falhar = true;
    final ordem = OrdemServico(
        id: 2,
        codigo: 'OS-2',
        clienteId: 1,
        equipamentoId: 1,
        descricaoProblema: 'Falha',
        prioridade: 'Média',
        status: 'Aberta',
        dataAbertura: DateTime(2026),
        valorMaoObraCentavos: 1000);
    await tester
        .pumpWidget(aplicativo(OrderDetailsPage(order: ordem), controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Financeiro'));
    await tester.pumpAndSettle();
    expect(find.text('Indisponível'), findsNWidgets(2));
    expect(find.text('R\$ 40,00'), findsNothing);
    expect(find.textContaining('SQLITE'), findsNothing);
    repo.falhar = false;
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Indisponível'), findsNothing);
    expect(find.text('R\$ 40,00'), findsOneWidget);
  });

  testWidgets('Formulário mantém mão de obra e orienta usar abas reais',
      (tester) async {
    await tester.pumpWidget(aplicativo(const OrderFormPage(), controller));
    await tester.pumpAndSettle();
    expect(find.text('Valor da mão de obra'), findsOneWidget);
    expect(
        find.textContaining('Financeiro para gerenciar peças'), findsOneWidget);
    expect(find.textContaining('Evidências para adicionar'), findsOneWidget);
    expect(find.text('Adicionar imagem'), findsNothing);
    expect(find.text('Valor de peças / materiais'), findsNothing);
    expect(find.text('Peças e materiais serão integrados na Etapa 7.'),
        findsNothing);
    expect(tester.takeException(), isNull);
  });
}
