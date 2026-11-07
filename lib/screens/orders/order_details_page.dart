import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/labeled_value.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';
import 'package:os_manutencao_ui/widgets/status_chip.dart';

/// Tela de consulta completa de uma ordem de serviço.
///
/// Todas as informações são mockadas. As abas existem para representar a
/// organização visual esperada para diagnóstico, financeiro, evidências e
/// histórico sem implementar persistência ou regras.
class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(order.code),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderFormPage(order: order)),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'Resumo'),
              Tab(icon: Icon(Icons.build_outlined), text: 'Serviço'),
              Tab(icon: Icon(Icons.payments_outlined), text: 'Financeiro'),
              Tab(icon: Icon(Icons.photo_library_outlined), text: 'Evidências'),
              Tab(icon: Icon(Icons.history), text: 'Histórico'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _SummaryTab(order: order),
            _ServiceTab(order: order),
            _FinancialTab(order: order),
            _EvidenceTab(order: order),
            _HistoryTab(order: order),
          ],
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: child,
        ),
      ),
    );
  }
}

class _SummaryTab extends StatelessWidget {
  const _SummaryTab({required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusChip(label: order.status, kind: statusKindFor(order.status)),
                      StatusChip(label: order.priority, kind: statusKindFor(order.priority)),
                      if (order.isLate)
                        const StatusChip(
                          label: 'Atrasada',
                          kind: StatusChipKind.danger,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final itemWidth = width >= 800 ? (width - 24) / 3 : width;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 20,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: LabeledValue(
                              label: 'Cliente',
                              value: order.client,
                              icon: Icons.business_outlined,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: LabeledValue(
                              label: 'Equipamento',
                              value: order.equipment,
                              icon: Icons.precision_manufacturing_outlined,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: LabeledValue(
                              label: 'Técnico responsável',
                              value: order.technician,
                              icon: Icons.engineering_outlined,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: const LabeledValue(
                              label: 'Data de abertura',
                              value: '19/08/2026',
                              icon: Icons.event_outlined,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: LabeledValue(
                              label: 'Prazo previsto',
                              value: order.deadline,
                              icon: Icons.event_busy_outlined,
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: LabeledValue(
                              label: 'Valor total',
                              value: 'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                              icon: Icons.payments_outlined,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Descrição do problema',
            child: Text(order.problem),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Ações disponíveis',
            subtitle: 'Os botões representam ações previstas, sem executar regras de negócio.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () {
                    // TODO(FUNCIONALIDADE): validar e efetuar mudança de status.
                  },
                  icon: const Icon(Icons.sync_alt),
                  label: const Text('Alterar status'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO(FUNCIONALIDADE): gerar comprovante ou relatório PDF,
                    // caso o aluno implemente esse diferencial opcional.
                  },
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Gerar comprovante'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showDeleteDialog(context),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir ordem'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir ordem de serviço?'),
        content: Text(
          'Confirma a exclusão de ${order.code}? Nesta versão visual, nenhuma informação será removida.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // TODO(FUNCIONALIDADE): verificar relacionamentos, permissões e
              // excluir a OS pelo repository. Depois, atualizar a listagem.
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
  }
}

class _ServiceTab extends StatelessWidget {
  const _ServiceTab({required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        children: [
          SectionCard(
            title: 'Diagnóstico técnico',
            child: Text(order.diagnosis),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Solução aplicada',
            child: Text(order.solution),
          ),
          const SizedBox(height: 16),
          const SectionCard(
            title: 'Observações do atendimento',
            child: Text(
              'DADO MOCKADO: cliente orientado sobre manutenção preventiva e periodicidade de inspeção.',
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialTab extends StatelessWidget {
  const _FinancialTab({required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        children: [
          SectionCard(
            title: 'Itens utilizados',
            subtitle: 'Valores demonstrativos sem cálculo ou persistência real.',
            child: Column(
              children: [
                const _FinancialRow(
                  description: 'Peça / material de exemplo',
                  quantity: '1',
                  unitValue: 'R\$ 240,00',
                ),
                const Divider(height: 28),
                const _FinancialRow(
                  description: 'Material de consumo',
                  quantity: '2',
                  unitValue: 'R\$ 45,00',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO(FUNCIONALIDADE): adicionar/remover itens vinculados à OS.
                    },
                    icon: const Icon(Icons.add_box_outlined),
                    label: const Text('Gerenciar itens'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Resumo financeiro',
            child: Column(
              children: [
                _MoneyLine(
                  label: 'Mão de obra',
                  value: 'R\$ ${order.laborValue.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                const SizedBox(height: 10),
                _MoneyLine(
                  label: 'Peças / materiais',
                  value: 'R\$ ${order.partsValue.toStringAsFixed(2).replaceAll('.', ',')}',
                ),
                const Divider(height: 30),
                _MoneyLine(
                  label: 'Total da OS',
                  value: 'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                  emphasized: true,
                ),
                const SizedBox(height: 12),
                const Text(
                  'TODO(FUNCIONALIDADE): substituir estes valores mockados pelo cálculo real da OS.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialRow extends StatelessWidget {
  const _FinancialRow({
    required this.description,
    required this.quantity,
    required this.unitValue,
  });

  final String description;
  final String quantity;
  final String unitValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(description)),
        const SizedBox(width: 12),
        Text('Qtd. $quantity'),
        const SizedBox(width: 20),
        Text(unitValue, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, style: style),
      ],
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab({required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: SectionCard(
        title: 'Imagens do atendimento',
        subtitle: order.hasEvidence
            ? 'Há espaços demonstrativos para evidências vinculadas à OS.'
            : 'Nenhuma evidência demonstrativa foi associada a esta OS.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (order.hasEvidence)
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: const [
                  _EvidenceCard(label: 'Antes da manutenção'),
                  _EvidenceCard(label: 'Defeito encontrado'),
                  _EvidenceCard(label: 'Após manutenção'),
                ],
              )
            else
              const Text('Nenhuma imagem cadastrada.'),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () {
                // TODO(FUNCIONALIDADE): selecionar/capturar imagem e associá-la
                // à ordem de serviço, incluindo descrição ou tipo da evidência.
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Adicionar evidência'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Imagem demonstrativa: $label',
      child: Container(
        width: 240,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 42),
            const SizedBox(height: 10),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.order});

  final MockOrderData order;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: SectionCard(
        title: 'Histórico da ordem',
        subtitle: 'Linha do tempo estática para demonstrar a evolução do atendimento.',
        child: Column(
          children: const [
            _HistoryItem(
              date: '19/08/2026 • 08:45',
              title: 'Ordem aberta',
              description: 'Solicitação registrada pelo atendimento.',
            ),
            _HistoryItem(
              date: '19/08/2026 • 09:10',
              title: 'Técnico atribuído',
              description: 'Responsável definido para o atendimento.',
            ),
            _HistoryItem(
              date: '19/08/2026 • 10:30',
              title: 'Status atualizado',
              description: 'Atendimento iniciado.',
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({
    required this.date,
    required this.title,
    required this.description,
  });

  final String date;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
