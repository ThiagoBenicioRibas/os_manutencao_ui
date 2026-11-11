import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário de cadastro e edição de ordens de serviço.
/// Mantém as seções da interface original e utiliza dados reais do SQLite.
class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key, this.order});

  final OrdemServico? order;

  bool get isEditing => order != null;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _problemaController;
  late final TextEditingController _diagnosticoController;
  late final TextEditingController _solucaoController;
  late final TextEditingController _observacoesController;
  late final TextEditingController _maoObraController;
  late final TextEditingController _aberturaController;
  late final TextEditingController _prazoController;

  int? _clienteId;
  int? _equipamentoId;
  int _tecnicoId = 0; // Zero representa uma OS sem técnico atribuído.
  late String _prioridade;
  late String _status;
  late DateTime _dataAbertura;
  DateTime? _prazoPrevisto;

  bool _carregandoVinculos = true;
  bool _salvando = false;
  bool _mostrarErroPrazo = false;
  String? _erroCarga;

  @override
  void initState() {
    super.initState();
    final ordem = widget.order;

    _clienteId = ordem?.clienteId;
    _equipamentoId = ordem?.equipamentoId;
    _tecnicoId = ordem?.tecnicoId ?? 0;
    _prioridade = ordem?.prioridade ?? 'Média';
    _status = ordem?.status ?? 'Aberta';
    _dataAbertura = ordem?.dataAbertura ?? DateTime.now();
    _prazoPrevisto = ordem?.prazoPrevisto;

    _problemaController = TextEditingController(text: ordem?.descricaoProblema ?? '');
    _diagnosticoController = TextEditingController(text: ordem?.diagnostico ?? '');
    _solucaoController = TextEditingController(text: ordem?.solucao ?? '');
    _observacoesController =
        TextEditingController(text: ordem?.observacoesAtendimento ?? '');
    _maoObraController = TextEditingController(
      text: _formatarCentavos(ordem?.valorMaoObraCentavos ?? 0),
    );
    _aberturaController = TextEditingController(text: _formatarData(_dataAbertura));
    _prazoController = TextEditingController(
      text: _prazoPrevisto == null ? '' : _formatarData(_prazoPrevisto!),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregarVinculos();
    });
  }

  @override
  void dispose() {
    _problemaController.dispose();
    _diagnosticoController.dispose();
    _solucaoController.dispose();
    _observacoesController.dispose();
    _maoObraController.dispose();
    _aberturaController.dispose();
    _prazoController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}/'
      '${data.month.toString().padLeft(2, '0')}/'
      '${data.year}';

  String _formatarCentavos(int centavos) =>
      '${centavos ~/ 100},${(centavos % 100).toString().padLeft(2, '0')}';

  String? _textoOpcional(String valor) {
    final texto = valor.trim();
    return texto.isEmpty ? null : texto;
  }

  String? _validarObrigatorio(String? valor) =>
      valor == null || valor.trim().isEmpty ? 'Este campo é obrigatório.' : null;

  String? _validarMaoObra(String? valor) {
    final texto = (valor ?? '').trim();
    if (texto.isEmpty) return null;
    if (!RegExp(r'^\d+([,.]\d{1,2})?$').hasMatch(texto)) {
      return 'Informe um valor válido, como 150,00 (sem separador de milhar).';
    }
    return null;
  }

  int _maoObraEmCentavos() {
    final texto = _maoObraController.text.trim().replaceAll('.', ',');
    if (texto.isEmpty) return 0;
    final partes = texto.split(',');
    final reais = int.tryParse(partes[0]) ?? 0;
    final centavos = partes.length == 1
        ? 0
        : (int.tryParse(partes[1].padRight(2, '0')) ?? 0);
    return reais * 100 + centavos;
  }

  Future<void> _carregarVinculos() async {
    setState(() {
      _carregandoVinculos = true;
      _erroCarga = null;
    });
    try {
      await Future.wait([
        context.read<ClienteController>().carregar(),
        context.read<EquipamentoController>().carregar(),
        context.read<TecnicoController>().carregar(),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() {
          _erroCarga = 'Não foi possível carregar clientes, equipamentos e técnicos.';
        });
      }
    } finally {
      if (mounted) setState(() => _carregandoVinculos = false);
    }
  }

  Future<void> _selecionarData({required bool abertura}) async {
    final dataAtual = abertura ? _dataAbertura : (_prazoPrevisto ?? DateTime.now());
    final selecionada = await showDatePicker(
      context: context,
      initialDate: dataAtual,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: abertura ? 'Selecionar data de abertura' : 'Selecionar prazo previsto',
    );
    if (!mounted || selecionada == null) return;
    setState(() {
      if (abertura) {
        _dataAbertura = selecionada;
        _aberturaController.text = _formatarData(selecionada);
      } else {
        _prazoPrevisto = selecionada;
        _prazoController.text = _formatarData(selecionada);
        _mostrarErroPrazo = false;
      }
    });
  }

  String _gerarCodigo() {
    final instante = DateTime.now().microsecondsSinceEpoch;
    final aleatorio = Random.secure().nextInt(1000000).toString().padLeft(6, '0');
    return 'OS-$instante-$aleatorio';
  }

  Future<void> _salvarOrdem() async {
    if (_salvando || _carregandoVinculos || _erroCarga != null) return;

    final formularioValido = _formKey.currentState!.validate();
    setState(() => _mostrarErroPrazo = _prazoPrevisto == null);
    if (!formularioValido || _prazoPrevisto == null) return;

    final clienteId = _clienteId;
    final equipamentoId = _equipamentoId;
    if (clienteId == null || equipamentoId == null) return;

    final equipamentos = context.read<EquipamentoController>().equipamentos;
    if (!equipamentos.any((e) => e.id == equipamentoId && e.clienteId == clienteId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O equipamento não pertence ao cliente selecionado.')),
      );
      return;
    }

    final ordemAnterior = widget.order;
    final ordem = OrdemServico(
      id: ordemAnterior?.id,
      codigo: ordemAnterior?.codigo ?? _gerarCodigo(),
      clienteId: clienteId,
      equipamentoId: equipamentoId,
      tecnicoId: _tecnicoId == 0 ? null : _tecnicoId,
      descricaoProblema: _problemaController.text.trim(),
      prioridade: _prioridade,
      status: _status,
      dataAbertura: _dataAbertura,
      prazoPrevisto: _prazoPrevisto,
      dataConclusao: _status == 'Concluída'
          ? (ordemAnterior?.dataConclusao ?? DateTime.now())
          : null,
      diagnostico: _textoOpcional(_diagnosticoController.text),
      solucao: _textoOpcional(_solucaoController.text),
      observacoesAtendimento: _textoOpcional(_observacoesController.text),
      valorMaoObraCentavos: _maoObraEmCentavos(),
    );

    setState(() => _salvando = true);
    try {
      final controlador = context.read<OrdemServicoController>();
      if (widget.isEditing) {
        await controlador.atualizar(ordem);
      } else {
        await controlador.cadastrar(ordem);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar a ordem. Confira os dados e tente novamente.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteController>().clientes;
    final equipamentos = context.watch<EquipamentoController>().equipamentos;
    final tecnicos = context.watch<TecnicoController>().tecnicos;
    final clienteExiste = clientes.any((c) => c.id == _clienteId);
    final equipamentosDoCliente =
        equipamentos.where((e) => e.clienteId == _clienteId).toList();
    final equipamentoExiste =
        equipamentosDoCliente.any((e) => e.id == _equipamentoId);
    final tecnicosDisponiveis = tecnicos
        .where((t) => t.situacao.toLowerCase() == 'ativo' || t.id == _tecnicoId)
        .toList();
    final tecnicoExiste =
        _tecnicoId == 0 || tecnicosDisponiveis.any((t) => t.id == _tecnicoId);
    final podeSalvar = !_salvando &&
        !_carregandoVinculos &&
        _erroCarga == null &&
        clientes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar ordem de serviço' : 'Nova ordem de serviço'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.isEditing
                        ? 'Atualize os dados da ${widget.order!.codigo}.'
                        : 'Preencha os dados do atendimento. O código será gerado ao salvar.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SectionCard(
                    title: 'Identificação e vínculo',
                    subtitle: 'Associe a ordem ao cliente, equipamento e técnico responsável.',
                    child: Column(
                      children: [
                        if (_carregandoVinculos) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 10),
                          const Text('Carregando dados cadastrados...'),
                          const SizedBox(height: 16),
                        ] else if (_erroCarga != null) ...[
                          Text(_erroCarga!),
                          TextButton.icon(
                            onPressed: _carregarVinculos,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ] else if (clientes.isEmpty) ...[
                          const Text('Cadastre um cliente antes de abrir uma ordem de serviço.'),
                          const SizedBox(height: 16),
                        ],
                        _ResponsiveFields(
                          children: [
                            TextFormField(
                              initialValue: widget.order?.codigo ?? 'Gerado ao salvar',
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Número / código da OS',
                                prefixIcon: Icon(Icons.tag),
                              ),
                            ),
                            DropdownButtonFormField<int>(
                              key: ValueKey('cliente-$_carregandoVinculos-$_clienteId'),
                              initialValue: clienteExiste ? _clienteId : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Cliente *',
                                prefixIcon: Icon(Icons.business_outlined),
                              ),
                              items: [
                                for (final c in clientes)
                                  if (c.id != null)
                                    DropdownMenuItem(
                                      value: c.id!,
                                      child: Text(c.nome, overflow: TextOverflow.ellipsis),
                                    ),
                              ],
                              onChanged: _salvando || _carregandoVinculos
                                  ? null
                                  : (valor) => setState(() {
                                        _clienteId = valor;
                                        _equipamentoId = null;
                                      }),
                              validator: (valor) => valor == null ? 'Selecione um cliente.' : null,
                            ),
                            DropdownButtonFormField<int>(
                              key: ValueKey('equipamento-$_clienteId-$_carregandoVinculos'),
                              initialValue: equipamentoExiste ? _equipamentoId : null,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Equipamento *',
                                prefixIcon: Icon(Icons.precision_manufacturing_outlined),
                              ),
                              items: [
                                for (final e in equipamentosDoCliente)
                                  if (e.id != null)
                                    DropdownMenuItem(
                                      value: e.id!,
                                      child: Text(
                                        [e.tipo, e.marca, e.modelo]
                                            .whereType<String>()
                                            .where((s) => s.trim().isNotEmpty)
                                            .join(' — '),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              ],
                              onChanged: _salvando || _clienteId == null
                                  ? null
                                  : (valor) => setState(() => _equipamentoId = valor),
                              validator: (valor) =>
                                  valor == null ? 'Selecione um equipamento do cliente.' : null,
                            ),
                            DropdownButtonFormField<int>(
                              key: ValueKey('tecnico-$_carregandoVinculos-$_tecnicoId'),
                              initialValue: tecnicoExiste ? _tecnicoId : 0,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Técnico responsável',
                                prefixIcon: Icon(Icons.engineering_outlined),
                              ),
                              items: [
                                const DropdownMenuItem(value: 0, child: Text('Sem técnico atribuído')),
                                for (final t in tecnicosDisponiveis)
                                  if (t.id != null)
                                    DropdownMenuItem(
                                      value: t.id!,
                                      child: Text(t.nome, overflow: TextOverflow.ellipsis),
                                    ),
                              ],
                              onChanged: _salvando
                                  ? null
                                  : (valor) => setState(() => _tecnicoId = valor ?? 0),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Atendimento, prioridade e prazo',
                    subtitle: 'Campos principais para acompanhar o ciclo da ordem.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _problemaController,
                          enabled: !_salvando,
                          validator: _validarObrigatorio,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Descrição do problema *',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.report_problem_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _ResponsiveFields(
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _prioridade,
                              decoration: const InputDecoration(
                                labelText: 'Prioridade *',
                                prefixIcon: Icon(Icons.flag_outlined),
                              ),
                              items: const ['Baixa', 'Média', 'Alta', 'Urgente']
                                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                  .toList(),
                              onChanged: _salvando
                                  ? null
                                  : (valor) => setState(() => _prioridade = valor ?? _prioridade),
                            ),
                            DropdownButtonFormField<String>(
                              initialValue: _status,
                              decoration: const InputDecoration(
                                labelText: 'Status *',
                                prefixIcon: Icon(Icons.sync_alt),
                              ),
                              items: const [
                                'Aberta', 'Atribuída', 'Em atendimento',
                                'Aguardando peça', 'Concluída', 'Cancelada',
                              ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: null, // Transições de status serão implementadas na Etapa 6.
                            ),
                            TextFormField(
                              controller: _aberturaController,
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Data de abertura',
                                prefixIcon: const Icon(Icons.event_outlined),
                                suffixIcon: IconButton(
                                  tooltip: 'Selecionar data de abertura',
                                  onPressed: _salvando ? null : () => _selecionarData(abertura: true),
                                  icon: const Icon(Icons.calendar_month_outlined),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _prazoController,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Prazo previsto *',
                                    prefixIcon: const Icon(Icons.event_busy_outlined),
                                    suffixIcon: IconButton(
                                      tooltip: 'Selecionar prazo previsto',
                                      onPressed: _salvando
                                          ? null
                                          : () => _selecionarData(abertura: false),
                                      icon: const Icon(Icons.calendar_month_outlined),
                                    ),
                                    errorText: _mostrarErroPrazo
                                        ? 'Selecione um prazo previsto.'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Diagnóstico e solução',
                    subtitle: 'Registre a análise técnica e a solução aplicada ao atendimento.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _diagnosticoController,
                          enabled: !_salvando,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Diagnóstico técnico',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.biotech_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _solucaoController,
                          enabled: !_salvando,
                          minLines: 3,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Solução aplicada',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.task_alt_outlined),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _observacoesController,
                          enabled: !_salvando,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Observações do atendimento',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.notes_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Peças, materiais e valores',
                    subtitle: 'A interface prevê mão de obra, peças e valor total da OS.',
                    child: Column(
                      children: [
                        _ResponsiveFields(
                          children: [
                            TextFormField(
                              controller: _maoObraController,
                              enabled: !_salvando,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: _validarMaoObra,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Valor da mão de obra',
                                prefixText: 'R\$ ',
                                prefixIcon: Icon(Icons.handyman_outlined),
                              ),
                            ),
                            TextFormField(
                              initialValue: '0,00',
                              readOnly: true,
                              decoration: InputDecoration(
                                labelText: 'Valor de peças / materiais',
                                prefixText: 'R\$ ',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: null,
                            icon: Icon(Icons.add_box_outlined),
                            label: Text('Adicionar peça ou material'),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calculate_outlined),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text('Subtotal da mão de obra',
                                    style: Theme.of(context).textTheme.titleMedium),
                              ),
                              Text(
                                'R\$ ${_validarMaoObra(_maoObraController.text) == null ? _formatarCentavos(_maoObraEmCentavos()) : '0,00'}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Peças e materiais serão integrados na Etapa 7.'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Imagens e evidências',
                    subtitle: 'Área reservada para fotos antes/depois, defeitos e peças substituídas.',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _EvidencePlaceholder(label: 'Antes da manutenção'),
                            _EvidencePlaceholder(label: 'Defeito encontrado'),
                            _EvidencePlaceholder(label: 'Após manutenção'),
                          ],
                        ),
                        SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: null,
                          icon: Icon(Icons.add_a_photo_outlined),
                          label: Text('Adicionar imagem'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _salvando ? null : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: podeSalvar ? _salvarOrdem : null,
                        icon: _salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _salvando
                              ? 'Salvando...'
                              : widget.isEditing
                                  ? 'Salvar alterações'
                                  : 'Salvar ordem',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Organiza campos lado a lado no desktop e empilhados em telas estreitas.
class _ResponsiveFields extends StatelessWidget {
  const _ResponsiveFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1) const SizedBox(height: 14),
              ],
            ],
          );
        }
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: children
              .map((child) => SizedBox(
                    width: (constraints.maxWidth - 14) / 2,
                    child: child,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _EvidencePlaceholder extends StatelessWidget {
  const _EvidencePlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Espaço para imagem: $label',
      child: Container(
        width: 190,
        height: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.image_outlined, size: 34),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
