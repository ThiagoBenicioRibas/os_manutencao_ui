import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/labeled_value.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';
import 'package:os_manutencao_ui/widgets/status_chip.dart';

/// Detalhes da OS real, conservando as cinco abas originais do professor.
class OrderDetailsPage extends StatefulWidget {
  const OrderDetailsPage({super.key, required this.order});

  final OrdemServico order;

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  late OrdemServico _ordem;
  bool _excluindo = false;

  @override
  void initState() {
    super.initState();
    _ordem = widget.order;
  }

  Future<void> _editar() async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderFormPage(order: _ordem)),
    );
    if (!mounted || alterou != true) return;
    final ordens = context.read<OrdemServicoController>().ordens;
    final novas = ordens.where((o) => o.id == _ordem.id);
    if (novas.isNotEmpty) setState(() => _ordem = novas.first);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ordem de serviço atualizada com sucesso.')),
    );
  }

  Future<void> _excluir() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir ordem de serviço?'),
        content: Text('Confirma a exclusão de ${_ordem.codigo}? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
    if (confirmou != true || !mounted || _ordem.id == null) return;
    setState(() => _excluindo = true);
    try {
      await context.read<OrdemServicoController>().excluir(_ordem.id!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a ordem de serviço.')),
      );
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomesClientes = {
      for (final c in context.watch<ClienteController>().clientes)
        if (c.id != null) c.id!: c.nome,
    };
    final nomesEquipamentos = {
      for (final e in context.watch<EquipamentoController>().equipamentos)
        if (e.id != null)
          e.id!: [e.tipo, e.marca, e.modelo]
              .whereType<String>()
              .where((s) => s.trim().isNotEmpty)
              .join(' — '),
    };
    final nomesTecnicos = {
      for (final t in context.watch<TecnicoController>().tecnicos)
        if (t.id != null) t.id!: t.nome,
    };
    final cliente = nomesClientes[_ordem.clienteId] ?? 'Cliente não encontrado';
    final equipamento =
        nomesEquipamentos[_ordem.equipamentoId] ?? 'Equipamento não encontrado';
    final tecnico = nomesTecnicos[_ordem.tecnicoId] ?? 'Sem técnico atribuído';

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_ordem.codigo),
          actions: [
            TextButton.icon(
              onPressed: _excluindo ? null : _editar,
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
            _Resumo(
              ordem: _ordem,
              cliente: cliente,
              equipamento: equipamento,
              tecnico: tecnico,
              excluindo: _excluindo,
              excluir: _excluir,
            ),
            _Servico(ordem: _ordem),
            _Financeiro(ordem: _ordem),
            const _Evidencias(),
            const _Historico(),
          ],
        ),
      ),
    );
  }
}

String _data(DateTime? data) => data == null
    ? 'Não definido'
    : '${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/${data.year}';

String _reais(int centavos) =>
    'R\$ ${centavos ~/ 100},${(centavos % 100).toString().padLeft(2, '0')}';

String _texto(String? valor) =>
    valor == null || valor.trim().isEmpty ? 'Não informado' : valor;

bool _atrasada(OrdemServico ordem) {
  final prazo = ordem.prazoPrevisto;
  if (prazo == null || ordem.status == 'Concluída' || ordem.status == 'Cancelada') {
    return false;
  }
  final hoje = DateTime.now();
  return DateTime(prazo.year, prazo.month, prazo.day)
      .isBefore(DateTime(hoje.year, hoje.month, hoje.day));
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

class _Resumo extends StatelessWidget {
  const _Resumo({
    required this.ordem,
    required this.cliente,
    required this.equipamento,
    required this.tecnico,
    required this.excluindo,
    required this.excluir,
  });

  final OrdemServico ordem;
  final String cliente;
  final String equipamento;
  final String tecnico;
  final bool excluindo;
  final VoidCallback excluir;

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
                      StatusChip(label: ordem.status, kind: statusKindFor(ordem.status)),
                      StatusChip(
                        label: ordem.prioridade,
                        kind: statusKindFor(ordem.prioridade),
                      ),
                      if (_atrasada(ordem))
                        const StatusChip(label: 'Atrasada', kind: StatusChipKind.danger),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LayoutBuilder(builder: (context, constraints) {
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
                            label: 'Cliente', value: cliente,
                            icon: Icons.business_outlined,
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: LabeledValue(
                            label: 'Equipamento', value: equipamento,
                            icon: Icons.precision_manufacturing_outlined,
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: LabeledValue(
                            label: 'Técnico responsável', value: tecnico,
                            icon: Icons.engineering_outlined,
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: LabeledValue(
                            label: 'Data de abertura', value: _data(ordem.dataAbertura),
                            icon: Icons.event_outlined,
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: LabeledValue(
                            label: 'Prazo previsto', value: _data(ordem.prazoPrevisto),
                            icon: Icons.event_busy_outlined,
                          ),
                        ),
                        SizedBox(
                          width: largura,
                          child: LabeledValue(
                            label: 'Mão de obra (parcial)',
                            value: _reais(ordem.valorMaoObraCentavos),
                            icon: Icons.payments_outlined,
                          ),
                        ),
                      ],
                    );
                  }),
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
            subtitle: 'Alteração de status e comprovante serão integrados em etapas posteriores.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: null,
                  icon: Icon(Icons.sync_alt),
                  label: Text('Alterar status'),
                ),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.picture_as_pdf_outlined),
                  label: Text('Gerar comprovante'),
                ),
                OutlinedButton.icon(
                  onPressed: excluindo ? null : excluir,
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
  const _Servico({required this.ordem});
  final OrdemServico ordem;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        children: [
          SectionCard(title: 'Diagnóstico técnico', child: Text(_texto(ordem.diagnostico))),
          const SizedBox(height: 16),
          SectionCard(title: 'Solução aplicada', child: Text(_texto(ordem.solucao))),
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

class _Financeiro extends StatelessWidget {
  const _Financeiro({required this.ordem});
  final OrdemServico ordem;

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: Column(
        children: [
          SectionCard(
            title: 'Itens utilizados',
            subtitle: 'O cadastro de peças e materiais será implementado na Etapa 7.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nenhum item apresentado nesta etapa.'),
                SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: null,
                  icon: Icon(Icons.add_box_outlined),
                  label: Text('Gerenciar itens'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Resumo financeiro',
            child: Column(
              children: [
                _MoneyLine(label: 'Mão de obra', value: _reais(ordem.valorMaoObraCentavos)),
                const SizedBox(height: 10),
                const _MoneyLine(label: 'Peças / materiais', value: 'A integrar'),
                const Divider(height: 30),
                _MoneyLine(
                  label: 'Subtotal da mão de obra',
                  value: _reais(ordem.valorMaoObraCentavos),
                  emphasized: true,
                ),
                const SizedBox(height: 12),
                const Text('O total completo da OS será calculado na Etapa 7.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLine extends StatelessWidget {
  const _MoneyLine({required this.label, required this.value, this.emphasized = false});
  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final estilo = emphasized
        ? Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
        : Theme.of(context).textTheme.bodyLarge;
    return Row(children: [
      Expanded(child: Text(label, style: estilo)),
      Text(value, style: estilo),
    ]);
  }
}

class _Evidencias extends StatelessWidget {
  const _Evidencias();

  @override
  Widget build(BuildContext context) {
    return _TabBody(
      child: SectionCard(
        title: 'Imagens do atendimento',
        subtitle: 'As evidências serão vinculadas ao SQLite na Etapa 7.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nenhuma imagem apresentada nesta etapa.'),
            SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: null,
              icon: Icon(Icons.add_a_photo_outlined),
              label: Text('Adicionar evidência'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Historico extends StatelessWidget {
  const _Historico();

  @override
  Widget build(BuildContext context) {
    return const _TabBody(
      child: SectionCard(
        title: 'Histórico da ordem',
        subtitle: 'O histórico real das mudanças de status será implementado na Etapa 6.',
        child: Text('Nenhuma movimentação apresentada nesta etapa.'),
      ),
    );
  }
}
