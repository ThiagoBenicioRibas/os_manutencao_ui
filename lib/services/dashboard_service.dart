import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/services/regras_ordem_servico.dart';

/// Calcula o painel sem depender da interface ou do banco de dados.
class DashboardService {
  const DashboardService();

  DashboardResumo calcular({
    required List<OrdemServico> ordens,
    required List<ItemUtilizado> itens,
    DateTime? referencia,
  }) {
    final hoje = referencia ?? DateTime.now();
    final porStatus = {
      for (final status in RegrasOrdemServico.statusPermitidos) status: 0,
    };
    final ids = <int>{};
    final alertas = <OrdemServico>[];
    var urgentes = 0;
    var atrasadas = 0;
    var valor = 0;
    for (final ordem in ordens) {
      porStatus.update(ordem.status, (total) => total + 1, ifAbsent: () => 1);
      if (ordem.id != null) ids.add(ordem.id!);
      valor += ordem.valorMaoObraCentavos;
      final urgente = ordem.prioridade == 'Urgente';
      final atrasada = RegrasOrdemServico.estaAtrasada(
        ordem,
        referencia: hoje,
      );
      if (urgente) urgentes++;
      if (atrasada) atrasadas++;
      final pendente =
          ordem.status != 'Concluída' && ordem.status != 'Cancelada';
      if (pendente &&
          (urgente || atrasada || ordem.status == 'Aguardando peça')) {
        alertas.add(ordem);
      }
    }
    for (final item in itens) {
      if (ids.contains(item.ordemId)) valor += item.subtotalCentavos;
    }
    return DashboardResumo(
      total: ordens.length,
      porStatus: Map.unmodifiable(porStatus),
      urgentes: urgentes,
      atrasadas: atrasadas,
      valorRegistradoCentavos: valor,
      alertas: List.unmodifiable(alertas.take(3)),
    );
  }
}

class DashboardResumo {
  const DashboardResumo({
    required this.total,
    required this.porStatus,
    required this.urgentes,
    required this.atrasadas,
    required this.valorRegistradoCentavos,
    required this.alertas,
  });

  final int total;
  final Map<String, int> porStatus;
  final int urgentes;
  final int atrasadas;
  final int valorRegistradoCentavos;
  final List<OrdemServico> alertas;

  int quantidade(String status) => porStatus[status] ?? 0;

  double fracao(String status) => total == 0 ? 0 : quantidade(status) / total;

  /// Formatação inteira, sem converter o valor monetário para ponto flutuante.
  String get valorFormatado {
    final reais = (valorRegistradoCentavos ~/ 100).toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]}.',
        );
    final centavos = (valorRegistradoCentavos % 100).toString().padLeft(2, '0');
    return 'R\$ $reais,$centavos';
  }
}
