import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Painel inicial que mantém os KPIs demonstrativos do professor.
///
/// As ordens exibidas em "Atenção necessária" vêm do SQLite.
/// Os indicadores estáticos serão integrados na etapa de Dashboard.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _carregando = true;
  String? _erro;

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
    try {
      await Future.wait([
        context.read<OrdemServicoController>().carregar(),
        context.read<ClienteController>().carregar(),
        context.read<EquipamentoController>().carregar(),
        context.read<TecnicoController>().carregar(),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível consultar as ordens.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirFormulario([OrdemServico? ordem]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderFormPage(order: ordem)),
    );
    if (!mounted || salvou != true) return;
    await _carregar();
  }

  Future<void> _abrirDetalhes(OrdemServico ordem) async {
    final excluiu = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderDetailsPage(order: ordem)),
    );
    if (!mounted || excluiu != true) return;
    await _carregar();
  }

  bool _estaAtrasada(OrdemServico ordem) {
    final prazo = ordem.prazoPrevisto;
    if (prazo == null ||
        ordem.status == 'Concluída' ||
        ordem.status == 'Cancelada') {
      return false;
    }
    final hoje = DateTime.now();
    return DateTime(prazo.year, prazo.month, prazo.day)
        .isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  @override
  Widget build(BuildContext context) {
    final ordens = context.watch<OrdemServicoController>().ordens;
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
    final alertas = ordens.where((ordem) =>
        ordem.prioridade == 'Urgente' ||
        ordem.status == 'Aguardando peça' ||
        _estaAtrasada(ordem)).take(3).toList();

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
                subtitle: 'Indicadores demonstrativos nesta etapa. Ordens em atenção são reais.',
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
                  final columns = width >= 1180 ? 4 : width >= 700 ? 2 : 1;
                  final cardWidth = (width - ((columns - 1) * 16)) / columns;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Total de ordens',
                          value: '42',
                          icon: Icons.assignment_outlined,
                          helper: 'Todos os status',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Ordens abertas',
                          value: '8',
                          icon: Icons.mark_email_unread_outlined,
                          helper: 'Aguardando atribuição',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Em atendimento',
                          value: '11',
                          icon: Icons.handyman_outlined,
                          helper: 'Atendimento em execução',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Aguardando peça',
                          value: '5',
                          icon: Icons.inventory_2_outlined,
                          helper: 'Dependem de material',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Concluídas',
                          value: '18',
                          icon: Icons.task_alt_outlined,
                          helper: 'Atendimentos finalizados',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Urgentes',
                          value: '4',
                          icon: Icons.priority_high,
                          helper: 'Prioridade crítica',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Atrasadas',
                          value: '3',
                          icon: Icons.warning_amber_outlined,
                          helper: 'Prazo vencido e não concluídas',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: const KpiCard(
                          label: 'Valor registrado',
                          value: 'R\$ 18.640,00',
                          icon: Icons.payments_outlined,
                          helper: 'Peças e mão de obra',
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
                    subtitle: 'Representação visual estática para o protótipo.',
                    child: const Column(
                      children: [
                        _ProgressLine(label: 'Abertas', value: 8, total: 42),
                        SizedBox(height: 14),
                        _ProgressLine(label: 'Em atendimento', value: 11, total: 42),
                        SizedBox(height: 14),
                        _ProgressLine(label: 'Aguardando peça', value: 5, total: 42),
                        SizedBox(height: 14),
                        _ProgressLine(label: 'Concluídas', value: 18, total: 42),
                      ],
                    ),
                  );

                  final alerts = SectionCard(
                    title: 'Atenção necessária',
                    subtitle: 'Ordens reais urgentes, atrasadas ou aguardando material.',
                    child: _carregando
                        ? const LinearProgressIndicator()
                        : _erro != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_erro!),
                                  TextButton.icon(
                                    onPressed: _carregar,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Tentar novamente'),
                                  ),
                                ],
                              )
                            : alertas.isEmpty
                                ? const Text('Nenhuma ordem exige atenção no momento.')
                                : Column(
                                    children: [
                                      for (final ordem in alertas)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 12),
                                          child: OrderCard(
                                            order: ordem,
                                            cliente: clientes[ordem.clienteId] ??
                                                'Cliente não encontrado',
                                            equipamento: equipamentos[ordem.equipamentoId] ??
                                                'Equipamento não encontrado',
                                            tecnico: tecnicos[ordem.tecnicoId] ??
                                                'Sem técnico atribuído',
                                            onView: () => _abrirDetalhes(ordem),
                                            onEdit: () => _abrirFormulario(ordem),
                                          ),
                                        ),
                                    ],
                                  ),
                  );

                  if (!wide) {
                    return Column(
                      children: [distribution, const SizedBox(height: 16), alerts],
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
  });

  final String label;
  final int value;
  final int total;

  @override
  Widget build(BuildContext context) {
    final fraction = value / total;
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
