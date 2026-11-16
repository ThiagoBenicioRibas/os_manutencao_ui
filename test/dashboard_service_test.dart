import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/services/dashboard_service.dart';
import 'package:os_manutencao_ui/services/regras_ordem_servico.dart';

OrdemServico ordem(
  int id, {
  String status = 'Aberta',
  String prioridade = 'Média',
  DateTime? prazo,
  int maoObra = 0,
}) =>
    OrdemServico(
      id: id,
      codigo: 'OS-$id',
      clienteId: 1,
      equipamentoId: 1,
      descricaoProblema: 'Manutenção',
      prioridade: prioridade,
      status: status,
      dataAbertura: DateTime(2026, 11, 1),
      prazoPrevisto: prazo,
      valorMaoObraCentavos: maoObra,
    );

void main() {
  const service = DashboardService();
  final hoje = DateTime(2026, 11, 16, 12);

  test('lista vazia tem seis status zerados e frações finitas', () {
    final resumo = service.calcular(ordens: [], itens: []);
    expect(resumo.total, 0);
    expect(resumo.urgentes, 0);
    expect(resumo.atrasadas, 0);
    expect(resumo.valorRegistradoCentavos, 0);
    expect(resumo.valorFormatado, 'R\$ 0,00');
    expect(resumo.alertas, isEmpty);
    expect(resumo.porStatus.keys, RegrasOrdemServico.statusPermitidos);
    for (final status in resumo.porStatus.keys) {
      expect(resumo.quantidade(status), 0);
      expect(resumo.fracao(status), 0);
    }
  });

  test('distribui todos os status e conta urgentes inclusive encerradas', () {
    final ordens = [
      ordem(1),
      ordem(2),
      ordem(3, status: 'Atribuída'),
      ordem(4, status: 'Em atendimento'),
      ordem(5, status: 'Aguardando peça'),
      ordem(6, status: 'Concluída', prioridade: 'Urgente'),
      ordem(7, status: 'Cancelada', prioridade: 'Urgente'),
    ];
    final resumo = service.calcular(ordens: ordens, itens: []);
    expect(resumo.total, 7);
    expect(resumo.quantidade('Aberta'), 2);
    for (final status in RegrasOrdemServico.statusPermitidos.skip(1)) {
      expect(resumo.quantidade(status), 1);
    }
    expect(resumo.fracao('Aberta'), closeTo(2 / 7, 0.000001));
    expect(resumo.urgentes, 2);
    expect(resumo.alertas.map((o) => o.id), [5]);
  });

  test('atraso considera dia, prazo ausente e exclui encerradas', () {
    final ontem = DateTime(2026, 11, 15, 23, 59);
    final resumo = service.calcular(ordens: [
      ordem(1, prazo: ontem),
      ordem(2, status: 'Atribuída', prazo: ontem),
      ordem(3, prazo: DateTime(2026, 11, 16)),
      ordem(4, prazo: DateTime(2026, 11, 17)),
      ordem(5),
      ordem(6, status: 'Concluída', prazo: ontem),
      ordem(7, status: 'Cancelada', prazo: ontem),
    ], itens: [], referencia: hoje);
    expect(resumo.atrasadas, 2);
    expect(resumo.alertas.map((o) => o.id), [1, 2]);
  });

  test('soma mão de obra e quantidade de itens em centavos de todos os status',
      () {
    final resumo = service.calcular(ordens: [
      ordem(1, maoObra: 10001),
      ordem(2, status: 'Concluída', maoObra: 20),
      ordem(3, status: 'Cancelada', maoObra: 30),
      ordem(4, maoObra: 100000),
    ], itens: const [
      ItemUtilizado(
          ordemId: 1,
          descricao: 'Peça',
          quantidade: 3,
          valorUnitarioCentavos: 33),
      ItemUtilizado(
          ordemId: 1,
          descricao: 'Material',
          quantidade: 2,
          valorUnitarioCentavos: 15),
      ItemUtilizado(
          ordemId: 2,
          descricao: 'Peça',
          quantidade: 1,
          valorUnitarioCentavos: 1),
      ItemUtilizado(
          ordemId: 3,
          descricao: 'Peça',
          quantidade: 1,
          valorUnitarioCentavos: 2),
      ItemUtilizado(
          ordemId: 99,
          descricao: 'Fora da lista',
          quantidade: 1,
          valorUnitarioCentavos: 999),
    ]);
    expect(resumo.valorRegistradoCentavos, 110183);
    expect(resumo.valorFormatado, 'R\$ 1.101,83');
  });

  test('alertas mantêm ordem da consulta, não duplicam e limitam a três', () {
    final resumo = service.calcular(ordens: [
      ordem(1, prioridade: 'Urgente', prazo: DateTime(2026, 11, 15)),
      ordem(2, status: 'Aguardando peça'),
      ordem(3, prioridade: 'Urgente'),
      ordem(4, prioridade: 'Urgente'),
    ], itens: [], referencia: hoje);
    expect(resumo.alertas.map((o) => o.id), [1, 2, 3]);
    expect(resumo.urgentes, 3);
    expect(resumo.atrasadas, 1);
  });

  test('itens sem ordens não geram valor registrado', () {
    final resumo = service.calcular(ordens: [], itens: const [
      ItemUtilizado(
          ordemId: 1,
          descricao: 'Peça',
          quantidade: 2,
          valorUnitarioCentavos: 100),
    ]);
    expect(resumo.valorRegistradoCentavos, 0);
  });
}
