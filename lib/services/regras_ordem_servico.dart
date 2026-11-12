
import 'package:os_manutencao_ui/models/ordem_servico.dart';

/// Centraliza as regras de negócio das ordens de serviço.
///
/// Não realiza operações diretamente no banco SQLite.
class RegrasOrdemServico {
  const RegrasOrdemServico._();

  /// Status previstos no guia do professor.
  static const List<String> statusPermitidos = [
    'Aberta',
    'Atribuída',
    'Em atendimento',
    'Aguardando peça',
    'Concluída',
    'Cancelada',
  ];

  /// Prioridades previstas na interface.
  static const List<String> prioridadesPermitidas = [
    'Baixa',
    'Média',
    'Alta',
    'Urgente',
  ];

  /// Define as mudanças de status permitidas.
  static const Map<String, List<String>> transicoesPermitidas = {
    'Aberta': [
      'Atribuída',
      'Em atendimento',
      'Cancelada',
    ],
    'Atribuída': [
      'Aberta',
      'Em atendimento',
      'Cancelada',
    ],
    'Em atendimento': [
      'Aguardando peça',
      'Concluída',
      'Cancelada',
    ],
    'Aguardando peça': [
      'Em atendimento',
      'Cancelada',
    ],
    'Concluída': [],
    'Cancelada': [],
  };

  /// Consulta os próximos status disponíveis.
  static List<String> proximosStatus(String statusAtual) {
    final transicoes = transicoesPermitidas[statusAtual];

    if (transicoes == null) {
      throw ArgumentError(
        'Status desconhecido: $statusAtual',
      );
    }

    return List<String>.unmodifiable(transicoes);
  }

  /// Valida uma mudança de status.
  ///
  /// Lança StateError caso alguma regra seja violada.
  static void validarTransicao(
    OrdemServico ordem,
    String novoStatus,
  ) {
    if (!statusPermitidos.contains(ordem.status)) {
      throw StateError(
        'O status atual da ordem é inválido: ${ordem.status}.',
      );
    }

    if (!statusPermitidos.contains(novoStatus)) {
      throw StateError(
        'O novo status informado é inválido: $novoStatus.',
      );
    }

    if (ordem.status == novoStatus) {
      throw StateError(
        'A ordem já está com o status $novoStatus.',
      );
    }

    final permitidos = transicoesPermitidas[ordem.status]!;

    if (!permitidos.contains(novoStatus)) {
      throw StateError(
        'Não é permitido alterar uma ordem de '
        '${ordem.status} para $novoStatus.',
      );
    }

    final exigeTecnico = novoStatus == 'Atribuída' ||
        novoStatus == 'Em atendimento' ||
        novoStatus == 'Aguardando peça';

    if (exigeTecnico && ordem.tecnicoId == null) {
      throw StateError(
        'É necessário atribuir um técnico antes '
        'de alterar a ordem para $novoStatus.',
      );
    }

    if (novoStatus == 'Concluída') {
      if (ordem.diagnostico == null ||
          ordem.diagnostico!.trim().isEmpty) {
        throw StateError(
          'Informe o diagnóstico técnico antes '
          'de concluir a ordem.',
        );
      }

      if (ordem.solucao == null ||
          ordem.solucao!.trim().isEmpty) {
        throw StateError(
          'Informe a solução aplicada antes '
          'de concluir a ordem.',
        );
      }
    }
  }

  /// Verifica se uma ordem está atrasada.
  ///
  /// Ordens concluídas ou canceladas não são consideradas
  /// pendentes em atraso.
  static bool estaAtrasada(
    OrdemServico ordem, {
    DateTime? referencia,
  }) {
    final prazo = ordem.prazoPrevisto;

    if (prazo == null) {
      return false;
    }

    if (ordem.status == 'Concluída' ||
        ordem.status == 'Cancelada') {
      return false;
    }

    final hoje = referencia ?? DateTime.now();

    final dataPrazo = DateTime.utc(
      prazo.year,
      prazo.month,
      prazo.day,
    );

    final dataAtual = DateTime.utc(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    return dataAtual.isAfter(dataPrazo);
  }

  /// Calcula quantos dias uma ordem está atrasada.
  ///
  /// Retorna zero quando não existe atraso.
  static int diasDeAtraso(
    OrdemServico ordem, {
    DateTime? referencia,
  }) {
    if (!estaAtrasada(ordem, referencia: referencia)) {
      return 0;
    }

    final prazo = ordem.prazoPrevisto!;
    final hoje = referencia ?? DateTime.now();

    final diaPrazo = DateTime.utc(
      prazo.year,
      prazo.month,
      prazo.day,
    );

    final diaAtual = DateTime.utc(
      hoje.year,
      hoje.month,
      hoje.day,
    );

    return diaAtual.difference(diaPrazo).inDays;
  }
}
