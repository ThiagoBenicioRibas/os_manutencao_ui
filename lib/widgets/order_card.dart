import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/widgets/status_chip.dart';

/// Card de uma ordem real, mantendo a apresentação original do professor.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.cliente,
    required this.equipamento,
    required this.tecnico,
    required this.onView,
    required this.onEdit,
  });

  final OrdemServico order;
  final String cliente;
  final String equipamento;
  final String tecnico;
  final VoidCallback onView;
  final VoidCallback onEdit;

  String _data(DateTime? data) => data == null
      ? 'Não definido'
      : '${data.day.toString().padLeft(2, '0')}/'
          '${data.month.toString().padLeft(2, '0')}/${data.year}';

  String _reais(int centavos) =>
      'R\$ ${centavos ~/ 100},${(centavos % 100).toString().padLeft(2, '0')}';

  bool get _atrasada {
    final prazo = order.prazoPrevisto;
    if (prazo == null ||
        order.status == 'Concluída' ||
        order.status == 'Cancelada') {
      return false;
    }
    final hoje = DateTime.now();
    return DateTime(prazo.year, prazo.month, prazo.day)
        .isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  @override
  Widget build(BuildContext context) {
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
                        order.codigo,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(cliente, style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                ),
                Flexible(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      StatusChip(label: order.status, kind: statusKindFor(order.status)),
                      StatusChip(
                        label: order.prioridade,
                        kind: statusKindFor(order.prioridade),
                      ),
                      if (_atrasada)
                        const StatusChip(
                          label: 'Atrasada',
                          kind: StatusChipKind.danger,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Info(icon: Icons.memory_outlined, text: equipamento),
                _Info(icon: Icons.engineering_outlined, text: tecnico),
                _Info(icon: Icons.event_outlined, text: 'Prazo: ${_data(order.prazoPrevisto)}'),
                _Info(
                  icon: Icons.payments_outlined,
                  text: 'Mão de obra: ${_reais(order.valorMaoObraCentavos)}',
                ),
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
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(text),
        ),
      ],
    );
  }
}
