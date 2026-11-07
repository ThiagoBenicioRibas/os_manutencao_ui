import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/status_chip.dart';

/// Card visual de uma ordem de serviço na listagem.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onView,
    required this.onEdit,
  });

  final MockOrderData order;
  final VoidCallback onView;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final currency = 'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.code,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.client,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    StatusChip(
                      label: order.status,
                      kind: statusKindFor(order.status),
                    ),
                    StatusChip(
                      label: order.priority,
                      kind: statusKindFor(order.priority),
                    ),
                    if (order.isLate)
                      const StatusChip(
                        label: 'Atrasada',
                        kind: StatusChipKind.danger,
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Info(icon: Icons.memory_outlined, text: order.equipment),
                _Info(icon: Icons.engineering_outlined, text: order.technician),
                _Info(icon: Icons.event_outlined, text: 'Prazo: ${order.deadline}'),
                _Info(icon: Icons.payments_outlined, text: currency),
                if (order.hasEvidence)
                  const _Info(icon: Icons.photo_library_outlined, text: 'Com evidências'),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: onView,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Ver detalhes'),
                ),
                OutlinedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(text),
        ),
      ],
    );
  }
}
