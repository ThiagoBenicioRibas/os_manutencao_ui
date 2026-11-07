import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/kpi_card.dart';
import 'package:os_manutencao_ui/widgets/order_card.dart';
import 'package:os_manutencao_ui/screens/orders/order_details_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Painel inicial com os indicadores solicitados no enunciado.
///
/// DADO MOCKADO: números e percentuais são fixos e existem apenas para mostrar
/// a aparência final do dashboard.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                subtitle: 'Resumo visual dos atendimentos e indicadores operacionais.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      // UI APENAS: abre o formulário vazio para demonstrar a tela.
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OrderFormPage()),
                      );
                    },
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
                    subtitle: 'Ordens urgentes, atrasadas ou aguardando material.',
                    child: Column(
                      children: MockData.orders.take(3).map((order) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: OrderCard(
                            order: order,
                            onView: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderDetailsPage(order: order),
                                ),
                              );
                            },
                            onEdit: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => OrderFormPage(order: order),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
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
