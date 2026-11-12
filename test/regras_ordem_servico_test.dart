import 'package:flutter_test/flutter_test.dart';

import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/services/regras_ordem_servico.dart';

/// Cria uma ordem de serviço fictícia para testar as regras de negócio.
///
/// Nenhum dado é salvo no SQLite por esta função.
OrdemServico _criarOrdem({
  String status = 'Aberta',
  String prioridade = 'Média',
  int? tecnicoId,
  String? diagnostico,
  String? solucao,
  DateTime? prazoPrevisto,
}) {
  return OrdemServico(
    id: 1,
    codigo: 'OS-TESTE-001',
    clienteId: 1,
    equipamentoId: 1,
    tecnicoId: tecnicoId,
    descricaoProblema: 'Notebook não liga.',
    prioridade: prioridade,
    status: status,
    dataAbertura: DateTime(2026, 11, 11),
    prazoPrevisto: prazoPrevisto,
    diagnostico: diagnostico,
    solucao: solucao,
    valorMaoObraCentavos: 0,
  );
}

void main() {
  group('Etapa 6 - Status e prioridades', () {
    test('Reconhece os seis status previstos pelo professor', () {
      expect(
        RegrasOrdemServico.statusPermitidos,
        [
          'Aberta',
          'Atribuída',
          'Em atendimento',
          'Aguardando peça',
          'Concluída',
          'Cancelada',
        ],
      );
    });

    test('Reconhece as quatro prioridades do formulário', () {
      expect(
        RegrasOrdemServico.prioridadesPermitidas,
        [
          'Baixa',
          'Média',
          'Alta',
          'Urgente',
        ],
      );
    });

    test('Consulta as próximas situações de uma ordem aberta', () {
      final proximos = RegrasOrdemServico.proximosStatus('Aberta');

      expect(
        proximos,
        [
          'Atribuída',
          'Em atendimento',
          'Cancelada',
        ],
      );
    });

    test('Não permite novos status para uma ordem concluída', () {
      expect(
        RegrasOrdemServico.proximosStatus('Concluída'),
        isEmpty,
      );
    });

    test('Não permite novos status para uma ordem cancelada', () {
      expect(
        RegrasOrdemServico.proximosStatus('Cancelada'),
        isEmpty,
      );
    });

    test('Rejeita a consulta de um status desconhecido', () {
      expect(
        () => RegrasOrdemServico.proximosStatus('Desconhecido'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Não permite modificar a lista de próximos status', () {
      final proximos = RegrasOrdemServico.proximosStatus('Aberta');

      expect(
        () => proximos.add('Concluída'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('Etapa 6 - Transições permitidas', () {
    final transicoesValidas = <(String, String)>[
      ('Aberta', 'Atribuída'),
      ('Aberta', 'Em atendimento'),
      ('Aberta', 'Cancelada'),
      ('Atribuída', 'Aberta'),
      ('Atribuída', 'Em atendimento'),
      ('Atribuída', 'Cancelada'),
      ('Em atendimento', 'Aguardando peça'),
      ('Em atendimento', 'Concluída'),
      ('Em atendimento', 'Cancelada'),
      ('Aguardando peça', 'Em atendimento'),
      ('Aguardando peça', 'Cancelada'),
    ];

    for (final (statusAtual, novoStatus) in transicoesValidas) {
      test('Permite $statusAtual para $novoStatus', () {
        final ordem = _criarOrdem(
          status: statusAtual,
          tecnicoId: 10,
          diagnostico: 'Defeito identificado na placa.',
          solucao: 'Placa reparada e equipamento testado.',
        );

        expect(
          () => RegrasOrdemServico.validarTransicao(
            ordem,
            novoStatus,
          ),
          returnsNormally,
        );
      });
    }
  });

  group('Etapa 6 - Transições proibidas', () {
    test('Impede alterar uma ordem para o mesmo status', () {
      final ordem = _criarOrdem(status: 'Aberta');

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Aberta',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede concluir uma ordem diretamente de Aberta', () {
      final ordem = _criarOrdem(
        status: 'Aberta',
        tecnicoId: 10,
        diagnostico: 'Defeito identificado.',
        solucao: 'Equipamento reparado.',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede alterar uma ordem concluída', () {
      final ordem = _criarOrdem(
        status: 'Concluída',
        tecnicoId: 10,
        diagnostico: 'Defeito identificado.',
        solucao: 'Equipamento reparado.',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Em atendimento',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede alterar uma ordem cancelada', () {
      final ordem = _criarOrdem(status: 'Cancelada');

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Aberta',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Rejeita novo status desconhecido', () {
      final ordem = _criarOrdem(status: 'Aberta');

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Em análise',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Rejeita uma ordem com status atual inválido', () {
      final ordem = _criarOrdem(status: 'Status inválido');

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Aberta',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('Etapa 6 - Atribuição de técnico', () {
    test('Impede atribuir a OS sem técnico responsável', () {
      final ordem = _criarOrdem(
        status: 'Aberta',
        tecnicoId: null,
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Atribuída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede iniciar atendimento sem técnico', () {
      final ordem = _criarOrdem(
        status: 'Aberta',
        tecnicoId: null,
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Em atendimento',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede aguardar peça sem técnico atribuído', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: null,
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Aguardando peça',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Permite cancelar uma ordem sem técnico', () {
      final ordem = _criarOrdem(
        status: 'Aberta',
        tecnicoId: null,
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Cancelada',
        ),
        returnsNormally,
      );
    });
  });

  group('Etapa 6 - Conclusão de ordem', () {
    test('Impede conclusão sem diagnóstico técnico', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: 10,
        diagnostico: null,
        solucao: 'Equipamento reparado.',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Impede conclusão sem solução aplicada', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: 10,
        diagnostico: 'Falha identificada.',
        solucao: null,
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Rejeita diagnóstico preenchido apenas com espaços', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: 10,
        diagnostico: '   ',
        solucao: 'Equipamento reparado.',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Rejeita solução preenchida apenas com espaços', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: 10,
        diagnostico: 'Defeito identificado.',
        solucao: '   ',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('Permite conclusão com diagnóstico e solução', () {
      final ordem = _criarOrdem(
        status: 'Em atendimento',
        tecnicoId: 10,
        diagnostico: 'Falha na alimentação elétrica.',
        solucao: 'Fonte reparada e notebook testado.',
      );

      expect(
        () => RegrasOrdemServico.validarTransicao(
          ordem,
          'Concluída',
        ),
        returnsNormally,
      );
    });
  });

  group('Etapa 6 - Prazo e atraso', () {
    test('Ordem sem prazo não é considerada atrasada', () {
      final ordem = _criarOrdem(prazoPrevisto: null);

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 20),
        ),
        isFalse,
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 20),
        ),
        0,
      );
    });

    test('Ordem antes do prazo não está atrasada', () {
      final ordem = _criarOrdem(
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 15),
        ),
        isFalse,
      );
    });

    test('Ordem no dia do prazo ainda não está atrasada', () {
      final ordem = _criarOrdem(
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 18, 23, 59),
        ),
        isFalse,
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 18, 23, 59),
        ),
        0,
      );
    });

    test('Ordem um dia após o prazo está atrasada', () {
      final ordem = _criarOrdem(
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 19),
        ),
        isTrue,
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 19),
        ),
        1,
      );
    });

    test('Calcula corretamente vários dias de atraso', () {
      final ordem = _criarOrdem(
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 23),
        ),
        5,
      );
    });

    test('Ordem concluída não permanece pendente em atraso', () {
      final ordem = _criarOrdem(
        status: 'Concluída',
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 23),
        ),
        isFalse,
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 23),
        ),
        0,
      );
    });

    test('Ordem cancelada não permanece pendente em atraso', () {
      final ordem = _criarOrdem(
        status: 'Cancelada',
        prazoPrevisto: DateTime(2026, 11, 18),
      );

      expect(
        RegrasOrdemServico.estaAtrasada(
          ordem,
          referencia: DateTime(2026, 11, 23),
        ),
        isFalse,
      );

      expect(
        RegrasOrdemServico.diasDeAtraso(
          ordem,
          referencia: DateTime(2026, 11, 23),
        ),
        0,
      );
    });
  });
}