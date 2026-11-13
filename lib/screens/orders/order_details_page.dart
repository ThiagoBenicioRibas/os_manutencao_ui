
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/historico_status_controller.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_items_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_evidences_page.dart';
import 'package:os_manutencao_ui/services/regras_ordem_servico.dart';
import 'package:os_manutencao_ui/widgets/labeled_value.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';
import 'package:os_manutencao_ui/widgets/status_chip.dart';

/// Detalhes da OS real, conservando as cinco abas originais do professor.
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({
    super.key,
    required this.order,
  });

  final OrdemServico order;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrdemServico _ordem;

  bool _excluindo = false;
  bool _alterandoStatus = false;

  @override
  void initState() {
    super.initState();
    _ordem = widget.order;

    // Consulta o histórico real depois que a tela é construída.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarHistorico();
      }
    });
  }

  /// Carrega o histórico da OS selecionada.
  Future<void> _carregarHistorico() async {
    final ordemId = _ordem.id;

    if (!mounted || ordemId == null) {
      return;
    }

    try {
      await context
          .read<HistoricoStatusController>()
          .carregarPorOrdem(ordemId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar o histórico da ordem.',
          ),
        ),
      );
    }
  }

  /// Edita os dados da ordem, preservando o formulário existente.
  Future<void> _editar() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => OrderFormPage(order: _ordem),
      ),
    );

    if (!mounted || alterou != true) {
      return;
    }

    final ordens = context.read<OrdemServicoController>().ordens;

    final novas = ordens.where(
      (ordem) => ordem.id == _ordem.id,
    );

    if (novas.isNotEmpty) {
      setState(() {
        _ordem = novas.first;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Ordem de serviço atualizada com sucesso.',
        ),
      ),
    );
  }

  /// Abre o diálogo e solicita a mudança de status.
  Future<void> _alterarStatus() async {
    final ordemId = _ordem.id;

    if (ordemId == null || _excluindo || _alterandoStatus) {
      return;
    }

    final proximosStatus = RegrasOrdemServico.proximosStatus(
      _ordem.status,
    );

    if (proximosStatus.isEmpty) {
      return;
    }

    final solicitacao = await showDialog<_AlteracaoStatusSolicitada>(
      context: context,
      builder: (_) => _AlterarStatusDialog(
        codigo: _ordem.codigo,
        statusAtual: _ordem.status,
        opcoes: proximosStatus,
      ),
    );

    if (!mounted || solicitacao == null) {
      return;
    }

    setState(() {
      _alterandoStatus = true;
    });

    try {
      // A atualização e o histórico são gravados
      // em uma única transação SQLite pelo repositório.
      await context.read<OrdemServicoController>().alterarStatus(
            ordemId: ordemId,
            novoStatus: solicitacao.novoStatus,
            observacao: solicitacao.observacao,
          );

      if (!mounted) {
        return;
      }

      // Atualiza os dados exibidos nas cinco abas.
      final ordens = context.read<OrdemServicoController>().ordens;

      final atualizadas = ordens.where(
        (ordem) => ordem.id == ordemId,
      );

      if (atualizadas.isNotEmpty) {
        setState(() {
          _ordem = atualizadas.first;
        });
      }

      // Consulta novamente o histórico depois da gravação.
      await _carregarHistorico();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status alterado para ${solicitacao.novoStatus}.',
          ),
        ),
      );
    } catch (erro) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não foi possível alterar o status: $erro',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _alterandoStatus = false;
        });
      }
    }
  }

  /// Exclui uma OS após confirmação do usuário.
  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ordem de serviço?'),
        content: Text(
          'Confirma a exclusão de ${_ordem.codigo}? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted || _ordem.id == null) {
      return;
    }

    setState(() {
      _excluindo = true;
    });

    try {
      await context
          .read<OrdemServicoController>()
          .excluir(_ordem.id!);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir a ordem de serviço.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindo = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomesClientes = {
      for (final cliente in context.watch<ClienteController>().clientes)
        if (cliente.id != null) cliente.id!: cliente.nome,
    };

    final nomesEquipamentos = {
      for (final equipamento
          in context.watch<EquipamentoController>().equipamentos)
        if (equipamento.id != null)
          equipamento.id!: [
            equipamento.tipo,
            equipamento.marca,
            equipamento.modelo,
          ]
              .whereType<String>()
              .where((texto) => texto.trim().isNotEmpty)
              .join(' — '),
    };

    final nomesTecnicos = {
      for (final tecnico in context.watch<TecnicoController>().tecnicos)
        if (tecnico.id != null) tecnico.id!: tecnico.nome,
    };

    final cliente =
        nomesClientes[_ordem.clienteId] ?? 'Cliente não encontrado';

    final equipamento =
        nomesEquipamentos[_ordem.equipamentoId] ??
            'Equipamento não encontrado';

    final tecnico =
        nomesTecnicos[_ordem.tecnicoId] ?? 'Sem técnico atribuído';

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_ordem.codigo),
          actions: [
            TextButton.icon(
              onPressed: (_excluindo || _alterandoStatus)
                  ? null
                  : _editar,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Editar'),
            ),
            const SizedBox(width: 8),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(
                icon: Icon(Icons.info_outline),
                text: 'Resumo',
              ),
              Tab(
                icon: Icon(Icons.build_outlined),
                text: 'Serviço',
              ),
              Tab(
                icon: Icon(Icons.payments_outlined),
                text: 'Financeiro',
              ),
              Tab(
                icon: Icon(Icons.photo_library_outlined),
                text: 'Evidências',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'Histórico',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _Resumo(
              ordem: _ordem,
              cliente: cliente,
              equipamento: equipamento,
              tecnico: tecnico,
              excluindo: _excluindo,
              alterandoStatus: _alterandoStatus,
              excluir: _excluir,
              alterarStatus: _alterarStatus,
            ),
            _Servico(ordem: _ordem),
            _Financeiro(ordem: _ordem),
            _Evidencias(ordem: _ordem),
            _Historico(ordemId: _ordem.id),
          ],
        ),
      ),
    );
  }
}

/// Dados devolvidos pelo diálogo de alteração de status.
class _AlteracaoStatusSolicitada {
  const _AlteracaoStatusSolicitada({
    required this.novoStatus,
    this.observacao,
  });

  final String novoStatus;
  final String? observacao;
}

/// Diálogo de seleção do próximo status.
class _AlterarStatusDialog extends StatefulWidget {
  const _AlterarStatusDialog({
    required this.codigo,
    required this.statusAtual,
    required this.opcoes,
  });

  final String codigo;
  final String statusAtual;
  final List<String> opcoes;

  @override
  State<_AlterarStatusDialog> createState() =>
      _AlterarStatusDialogState();
}

class _AlterarStatusDialogState extends State<_AlterarStatusDialog> {
  final TextEditingController _observacaoController =
      TextEditingController();

  String? _statusSelecionado;

  @override
  void dispose() {
    _observacaoController.dispose();
    super.dispose();
  }

  void _confirmar() {
    final status = _statusSelecionado;

    if (status == null) {
      return;
    }

    final observacao = _observacaoController.text.trim();

    Navigator.of(context).pop(
      _AlteracaoStatusSolicitada(
        novoStatus: status,
        observacao: observacao.isEmpty ? null : observacao,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Alterar status'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ordem de serviço: ${widget.codigo}'),
              const SizedBox(height: 8),
              Text('Status atual: ${widget.statusAtual}'),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _statusSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Novo status',
                  border: OutlineInputBorder(),
                ),
                items: widget.opcoes.map((status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (valor) {
                  setState(() {
                    _statusSelecionado = valor;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _observacaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observação (opcional)',
                  border: OutlineInputBorder(),
                  hintText: 'Descreva o motivo da alteração',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'A alteração será registrada no histórico '
                'da ordem de serviço.',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _statusSelecionado == null
              ? null
              : _confirmar,
          child: const Text('Confirmar alteração'),
        ),
      ],
    );
  }
}

String _data(DateTime? data) {
  if (data == null) {
    return 'Não definido';
  }

  return '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';
}

String _dataHora(DateTime data) {
  final horas = data.hour.toString().padLeft(2, '0');
  final minutos = data.minute.toString().padLeft(2, '0');

  return '${_data(data)} às $horas:$minutos';
}

String _reais(int centavos) =>
    'R\$ ${centavos ~/ 100},'
    '${(centavos % 100).toString().padLeft(2, '0')}';

String _texto(String? valor) {
  if (valor == null || valor.trim().isEmpty) {
    return 'Não informado';
  }

  return valor;
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.child,
  });

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

class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.ordem,
    required this.cliente,
    required this.equipamento,
    required this.tecnico,
    required this.excluindo,
    required this.alterandoStatus,
    required this.excluir,
    required this.alterarStatus,
  });

  final OrdemServico ordem;
  final String cliente;
  final String equipamento;
  final String tecnico;
  final bool excluindo;
  final bool alterandoStatus;
  final VoidCallback excluir;
  final VoidCallback alterarStatus;

  @override
  Widget build(BuildContext context) {
    final possuiProximosStatus =
        RegrasOrdemServico.proximosStatus(ordem.status).isNotEmpty;

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
                      StatusChip(
                        label: ordem.status,
                        kind: statusKindFor(ordem.status),
                      ),
                      StatusChip(
                        label: ordem.prioridade,
                        kind: statusKindFor(ordem.prioridade),
                      ),
                      if (RegrasOrdemServico.estaAtrasada(ordem))
                        const StatusChip(
                          label: 'Atrasada',
                          kind: StatusChipKind.danger,
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final largura = constraints.maxWidth >= 800
                          ? (constraints.maxWidth - 24) / 3
                          : constraints.maxWidth;

                      return Wrap(
                        spacing: 12,
                        runSpacing: 20,
                        children: [
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Cliente',
                              value: cliente,
                              icon: Icons.business_outlined,
                            ),
                          ),
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Equipamento',
                              value: equipamento,
                              icon: Icons.precision_manufacturing_outlined,
                            ),
                          ),
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Técnico responsável',
                              value: tecnico,
                              icon: Icons.engineering_outlined,
                            ),
                          ),
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Data de abertura',
                              value: _data(ordem.dataAbertura),
                              icon: Icons.event_outlined,
                            ),
                          ),
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Prazo previsto',
                              value: _data(ordem.prazoPrevisto),
                              icon: Icons.event_busy_outlined,
                            ),
                          ),
                          SizedBox(
                            width: largura,
                            child: LabeledValue(
                              label: 'Mão de obra (parcial)',
                              value: _reais(
                                ordem.valorMaoObraCentavos,
                              ),
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
            child: Text(ordem.descricaoProblema),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Ações disponíveis',
            subtitle:
                'As alterações de status são registradas no histórico.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: excluindo ||
                          alterandoStatus ||
                          !possuiProximosStatus
                      ? null
                      : alterarStatus,
                  icon: const Icon(Icons.sync_alt),
                  label: Text(
                    alterandoStatus
                        ? 'Alterando status...'
                        : 'Alterar status',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Gerar comprovante'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      (excluindo || alterandoStatus) ? null : excluir,
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
}

class _Servico extends StatelessWidget {
  const _Servico({
    required this.ordem,
  });

  final OrdemServico ordem;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        children: [
          SectionCard(
            title: 'Diagnóstico técnico',
            child: Text(_texto(ordem.diagnostico)),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Solução aplicada',
            child: Text(_texto(ordem.solucao)),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Observações do atendimento',
            child: Text(_texto(ordem.observacoesAtendimento)),
          ),
        ],
      ),
    );
  }
}

class _Financeiro extends StatefulWidget {
  const _Financeiro({
    required this.ordem,
  });

  final OrdemServico ordem;

  @override
  State<_Financeiro> createState() => _FinanceiroState();
}

class _FinanceiroState extends State<_Financeiro> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarMateriais();
      }
    });
  }

  Future<void> _carregarMateriais() async {
    final ordemId = widget.ordem.id;
    if (ordemId == null || !mounted) return;

    try {
      await context.read<ItemUtilizadoController>().carregarPorOrdem(ordemId);
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível carregar os materiais da OS.'),
        ),
      );
    }
  }

  Future<void> _gerenciarMateriais() async {
    final ordemId = widget.ordem.id;
    if (ordemId == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => OrderItemsPage(
          ordemId: ordemId,
          codigo: widget.ordem.codigo,
        ),
      ),
    );

    if (mounted) {
      await _carregarMateriais();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ItemUtilizadoController>();
    final ordemId = widget.ordem.id;

    // Não apresenta materiais de outra OS caso um filtro antigo
    // ainda esteja ativo no controlador compartilhado.
    final dadosDaOrdem = ordemId != null &&
        controlador.ordemIdFiltro == ordemId;
    final itens = dadosDaOrdem
        ? controlador.itens.where((item) => item.ordemId == ordemId).toList()
        : [];

    final totalMateriaisCentavos = dadosDaOrdem ? controlador.totalCentavos : 0;
    final totalOrdemCentavos =
        widget.ordem.valorMaoObraCentavos + totalMateriaisCentavos;
    final carregando = controlador.carregando || !dadosDaOrdem;

    return _TabBody(
      child: Column(
        children: [
          SectionCard(
            title: 'Itens utilizados',
            subtitle: 'Peças e materiais vinculados a esta ordem de serviço.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (carregando)
                  const Text('Carregando materiais...')
                else if (controlador.erro != null)
                  Text(controlador.erro!)
                else if (itens.isEmpty)
                  const Text('Nenhuma peça ou material cadastrado.')
                else ...[
                  for (final item in itens)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${item.descricao}: ${item.quantidade} × '
                        '${_reais(item.valorUnitarioCentavos)} = '
                        '${_reais(item.subtotalCentavos)}',
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: ordemId == null || controlador.carregando
                      ? null
                      : _gerenciarMateriais,
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Gerenciar itens'),
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
                  value: _reais(widget.ordem.valorMaoObraCentavos),
                ),
                const SizedBox(height: 10),
                _MoneyLine(
                  label: 'Peças / materiais',
                  value: carregando
                      ? 'Carregando...'
                      : _reais(totalMateriaisCentavos),
                ),
                const Divider(height: 30),
                _MoneyLine(
                  label: 'Total da Ordem de Serviço',
                  value: carregando ? 'Carregando...' : _reais(totalOrdemCentavos),
                  emphasized: true,
                ),
              ],
            ),
          ),
        ],
      ),
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
    final estilo = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            )
        : Theme.of(context).textTheme.bodyLarge;

    return Row(
      children: [
        Expanded(
          child: Text(label, style: estilo),
        ),
        Text(value, style: estilo),
      ],
    );
  }
}

class _Evidencias extends StatelessWidget {
  const _Evidencias({required this.ordem});

  final OrdemServico ordem;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: SectionCard(
        title: 'Imagens do atendimento',
        subtitle: 'Fotografias vinculadas a esta ordem de serviço.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Adicione, visualize ou exclua fotografias do atendimento.',
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: ordem.id == null
                  ? null
                  : () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => OrderEvidencesPage(
                            ordemId: ordem.id!,
                            codigo: ordem.codigo,
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Gerenciar evidências'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Apresenta os registros reais das mudanças de status.
class _Historico extends StatelessWidget {
  const _Historico({
    required this.ordemId,
  });

  final int? ordemId;

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<HistoricoStatusController>();

    final registros = controlador.historicos
        .where((historico) => historico.ordemId == ordemId)
        .toList();

    Widget conteudo;

    if (controlador.carregando) {
      conteudo = const Center(
        child: CircularProgressIndicator(),
      );
    } else if (controlador.erro != null) {
      conteudo = Text(controlador.erro!);
    } else if (registros.isEmpty) {
      conteudo = const Text(
        'Nenhuma mudança de status registrada para esta ordem.',
      );
    } else {
      conteudo = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var indice = 0; indice < registros.length; indice++) ...[
            if (indice > 0)
              const Divider(height: 28),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${registros[indice].statusAnterior ?? 'Início'} '
                        '→ ${registros[indice].statusNovo}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _dataHora(
                          registros[indice].dataAlteracao,
                        ),
                      ),
                      if (registros[indice].observacao != null &&
                          registros[indice]
                              .observacao!
                              .trim()
                              .isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          registros[indice].observacao!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return _TabBody(
      child: SectionCard(
        title: 'Histórico da ordem',
        subtitle:
            'Registro das mudanças de status desta ordem de serviço.',
        child: conteudo,
      ),
    );
  }
}
