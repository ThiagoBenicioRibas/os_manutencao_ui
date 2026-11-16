import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';
import 'package:os_manutencao_ui/services/dashboard_service.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/kpi_card.dart';
import 'package:os_manutencao_ui/widgets/order_card.dart';
import 'package:os_manutencao_ui/screens/orders/order_details_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Painel calculado a partir dos registros persistidos.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _carregando = true;
  String? _erro;
  DashboardResumo? _resumo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    final ordens = context.read<OrdemServicoController>();
    try {
      await Future.wait([
        ordens.carregar(),
        context.read<ClienteController>().carregar(),
        context.read<EquipamentoController>().carregar(),
        context.read<TecnicoController>().carregar(),
      ]);
      final itens = await ItemUtilizadoRepository().listar();
      final resumo = const DashboardService().calcular(
        ordens: ordens.ordens,
        itens: itens,
      );
      if (mounted) setState(() => _resumo = resumo);
    } catch (_) {
      if (mounted) {
        setState(() =>
            _erro = 'Não foi possível carregar o Dashboard. Tente novamente.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirFormulario([OrdemServico? ordem]) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderFormPage(order: ordem)),
    );
    if (!mounted) return;
    await _carregar();
  }

  Future<void> _abrirDetalhes(OrdemServico ordem) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderDetailsPage(order: ordem)),
    );
    if (!mounted) return;
    await _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final resumo = _carregando || _erro != null ? null : _resumo;
    final clientes = {
      for (final c in context.watch<ClienteController>().clientes)
        if (c.id != null) c.id!: c.nome,
    };
    final equipamentos = {
      for (final e in context.watch<EquipamentoController>().equipamentos)
        if (e.id != null)
          e.id!: [e.tipo, e.marca, e.modelo]
              .whereType<String>()
              .where((parte) => parte.trim().isNotEmpty)
              .join(' — '),
    };
    final tecnicos = {
      for (final t in context.watch<TecnicoController>().tecnicos)
        if (t.id != null) t.id!: t.nome,
    };
    final alertas = resumo?.alertas ?? <OrdemServico>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Dashboard',
                subtitle: 'Resumo das ordens de serviço registradas.',
                actions: [
                  FilledButton.icon(
                    onPressed: _carregando ? null : () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova ordem de serviço'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 1180
                      ? 4
                      : width >= 700
                          ? 2
                          : 1;
                  final cardWidth = (width - ((columns - 1) * 16)) / columns;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Total de ordens',
                          value: resumo?.total.toString() ?? 'Indisponível',
                          icon: Icons.assignment_outlined,
                          helper: 'Todos os status',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Ordens abertas',
                          value: resumo?.quantidade('Aberta').toString() ??
                              'Indisponível',
                          icon: Icons.mark_email_unread_outlined,
                          helper: 'Aguardando atribuição',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Em atendimento',
                          value:
                              resumo?.quantidade('Em atendimento').toString() ??
                                  'Indisponível',
                          icon: Icons.handyman_outlined,
                          helper: 'Atendimento em execução',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Aguardando peça',
                          value: resumo
                                  ?.quantidade('Aguardando peça')
                                  .toString() ??
                              'Indisponível',
                          icon: Icons.inventory_2_outlined,
                          helper: 'Dependem de material',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Concluídas',
                          value: resumo?.quantidade('Concluída').toString() ??
                              'Indisponível',
                          icon: Icons.task_alt_outlined,
                          helper: 'Atendimentos finalizados',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Urgentes',
                          value: resumo?.urgentes.toString() ?? 'Indisponível',
                          icon: Icons.priority_high,
                          helper: 'Prioridade urgente em todos os status',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Atrasadas',
                          value: resumo?.atrasadas.toString() ?? 'Indisponível',
                          icon: Icons.warning_amber_outlined,
                          helper: 'Pendentes com prazo vencido',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: KpiCard(
                          label: 'Valor registrado',
                          value: resumo?.valorFormatado ?? 'Indisponível',
                          icon: Icons.payments_outlined,
                          helper: 'Peças e mão de obra de todos os status',
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 980;
                  final distribution = SectionCard(
                    title: 'Distribuição por status',
                    subtitle: 'Todas as ordens, agrupadas por status.',
                    child: resumo == null
                        ? const Text('Distribuição indisponível.')
                        : Column(
                            children: [
                              for (final status in resumo.porStatus.keys)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _ProgressLine(
                                      label: status,
                                      value: resumo.quantidade(status),
                                      total: resumo.total,
                                      fraction: resumo.fracao(status)),
                                ),
                            ],
                          ),
                  );

                  final alerts = SectionCard(
                    title: 'Atenção necessária',
                    subtitle:
                        'Até três ordens pendentes urgentes, atrasadas ou aguardando material.',
                    child: _carregando
                        ? const LinearProgressIndicator(
                            semanticsLabel: 'Carregando Dashboard')
                        : _erro != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Semantics(
                                      liveRegion: true, child: Text(_erro!)),
                                  TextButton.icon(
                                    onPressed: _carregar,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Tentar novamente'),
                                  ),
                                ],
                              )
                            : alertas.isEmpty
                                ? const Text(
                                    'Nenhuma ordem exige atenção no momento.')
                                : Column(
                                    children: [
                                      for (final ordem in alertas)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 12),
                                          child: OrderCard(
                                            order: ordem,
                                            cliente:
                                                clientes[ordem.clienteId] ??
                                                    'Cliente não encontrado',
                                            equipamento: equipamentos[
                                                    ordem.equipamentoId] ??
                                                'Equipamento não encontrado',
                                            tecnico:
                                                tecnicos[ordem.tecnicoId] ??
                                                    'Sem técnico atribuído',
                                            onView: () => _abrirDetalhes(ordem),
                                            onEdit: () =>
                                                _abrirFormulario(ordem),
                                          ),
                                        ),
                                    ],
                                  ),
                  );

                  if (!wide) {
                    return Column(
                      children: [
                        distribution,
                        const SizedBox(height: 16),
                        alerts
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: distribution),
                      const SizedBox(width: 16),
                      Expanded(flex: 3, child: alerts),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.total,
    required this.fraction,
  });

  final String label;
  final int value;
  final int total;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: $value de $total ordens',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label)),
              Text('$value'),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: fraction),
        ],
      ),
    );
  }
}
