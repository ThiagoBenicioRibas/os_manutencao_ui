import 'package:flutter/material.dart';

/// Chip visual para representar status, prioridade ou alertas.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.kind = StatusChipKind.neutral,
  });

  final String label;
  final StatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: colors.$2),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colors.$3,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }

  (Color, Color, Color) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (kind) {
      case StatusChipKind.success:
        return (
          const Color(0xFFE8F5E9),
          const Color(0xFFA5D6A7),
          const Color(0xFF1B5E20),
        );
      case StatusChipKind.warning:
        return (
          const Color(0xFFFFF8E1),
          const Color(0xFFFFD54F),
          const Color(0xFF7A4F00),
        );
      case StatusChipKind.danger:
        return (
          const Color(0xFFFFEBEE),
          const Color(0xFFEF9A9A),
          const Color(0xFF8E1620),
        );
      case StatusChipKind.info:
        return (
          const Color(0xFFE3F2FD),
          const Color(0xFF90CAF9),
          const Color(0xFF0D47A1),
        );
      case StatusChipKind.neutral:
        return (
          scheme.surfaceContainerHighest,
          scheme.outlineVariant,
          scheme.onSurfaceVariant,
        );
    }
  }
}

enum StatusChipKind { neutral, info, success, warning, danger }

/// Traduz os textos mockados para um estilo de chip coerente.
///
/// UI APENAS: esta função escolhe somente cor visual. Ela não valida o fluxo
/// real de status da ordem de serviço.
StatusChipKind statusKindFor(String value) {
  switch (value) {
    case 'Concluída':
    case 'Ativo':
      return StatusChipKind.success;
    case 'Urgente':
    case 'Atrasada':
      return StatusChipKind.danger;
    case 'Aguardando peça':
    case 'Alta':
      return StatusChipKind.warning;
    case 'Em atendimento':
    case 'Atribuída':
      return StatusChipKind.info;
    default:
      return StatusChipKind.neutral;
  }
}
