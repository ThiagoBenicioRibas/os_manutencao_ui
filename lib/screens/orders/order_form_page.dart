import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário visual para abertura ou edição de uma ordem de serviço.
///
/// UI APENAS: nenhum campo é salvo. Dropdowns mantêm somente o estado visual da
/// tela para permitir a inspeção do protótipo.
class OrderFormPage extends StatefulWidget {
  const OrderFormPage({super.key, this.order});

  final MockOrderData? order;

  bool get isEditing => order != null;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  late String _client;
  late String _equipment;
  late String _technician;
  late String _status;
  late String _priority;

  @override
  void initState() {
    super.initState();
    _client = widget.order?.client ?? 'Clínica Horizonte';
    _equipment = widget.order?.equipment ?? 'Ar-condicionado Split 24.000 BTU';
    _technician = widget.order?.technician ?? 'Carlos Almeida';
    _status = widget.order?.status ?? 'Aberta';
    _priority = widget.order?.priority ?? 'Média';
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing
            ? 'Editar ordem de serviço'
            : 'Nova ordem de serviço'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.isEditing
                      ? 'Atualize visualmente os dados da ${order!.code}. Nenhuma alteração será salva nesta versão.'
                      : 'Preencha os dados do atendimento. O botão Salvar está sem implementação propositalmente.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                SectionCard(
                  title: 'Identificação e vínculo',
                  subtitle:
                      'Associe a ordem ao cliente, equipamento e técnico responsável.',
                  child: _ResponsiveFields(
                    children: [
                      TextFormField(
                        initialValue: order?.code ?? 'Gerado ao salvar',
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Número / código da OS',
                          prefixIcon: Icon(Icons.tag),
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        value: _client,
                        decoration: const InputDecoration(
                          labelText: 'Cliente *',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: const [
                          'Clínica Horizonte',
                          'Escritório Delta',
                          'Padaria Avenida',
                          'Condomínio Jardim Sul',
                        ]
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          // UI APENAS: muda somente a seleção do componente.
                          // TODO(FUNCIONALIDADE): ao trocar o cliente, carregar os
                          // equipamentos vinculados a ele a partir do controller.
                          if (value != null) setState(() => _client = value);
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: _equipment,
                        decoration: const InputDecoration(
                          labelText: 'Equipamento *',
                          prefixIcon:
                              Icon(Icons.precision_manufacturing_outlined),
                        ),
                        items: const [
                          'Ar-condicionado Split 24.000 BTU',
                          'Notebook Lenovo ThinkPad E14',
                          'Freezer horizontal Metalfrio',
                          'Bomba d’água Schneider',
                        ]
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          // UI APENAS: estado temporário da interface.
                          if (value != null) setState(() => _equipment = value);
                          // TODO(FUNCIONALIDADE): validar se o equipamento pertence
                          // ao cliente selecionado.
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: _technician,
                        decoration: const InputDecoration(
                          labelText: 'Técnico responsável',
                          prefixIcon: Icon(Icons.engineering_outlined),
                        ),
                        items: const [
                          'Carlos Almeida',
                          'Fernanda Souza',
                          'Rafael Martins',
                        ]
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          // UI APENAS: estado temporário da interface.
                          if (value != null)
                            setState(() => _technician = value);
                          // TODO(FUNCIONALIDADE): carregar somente técnicos ativos
                          // e persistir a atribuição da OS.
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Atendimento, prioridade e prazo',
                  subtitle:
                      'Campos principais para acompanhar o ciclo da ordem.',
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: order?.problem,
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
                            value: _priority,
                            decoration: const InputDecoration(
                              labelText: 'Prioridade *',
                              prefixIcon: Icon(Icons.flag_outlined),
                            ),
                            items: const ['Baixa', 'Média', 'Alta', 'Urgente']
                                .map((item) => DropdownMenuItem(
                                    value: item, child: Text(item)))
                                .toList(),
                            onChanged: (value) {
                              // UI APENAS: atualiza o controle visual.
                              if (value != null)
                                setState(() => _priority = value);
                              // TODO(FUNCIONALIDADE): persistir e aplicar as regras
                              // de destaque de prioridade.
                            },
                          ),
                          DropdownButtonFormField<String>(
                            value: _status,
                            decoration: const InputDecoration(
                              labelText: 'Status *',
                              prefixIcon: Icon(Icons.sync_alt),
                            ),
                            items: const [
                              'Aberta',
                              'Atribuída',
                              'Em atendimento',
                              'Aguardando peça',
                              'Concluída',
                              'Cancelada',
                            ]
                                .map((item) => DropdownMenuItem(
                                    value: item, child: Text(item)))
                                .toList(),
                            onChanged: (value) {
                              // UI APENAS: troca o texto selecionado.
                              if (value != null)
                                setState(() => _status = value);
                              // TODO(FUNCIONALIDADE): validar transições permitidas.
                              // Exemplo: impedir conclusão sem diagnóstico/solução.
                            },
                          ),
                          TextFormField(
                            initialValue: '19/08/2026',
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Data de abertura',
                              prefixIcon: const Icon(Icons.event_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Selecionar data de abertura',
                                onPressed: () {
                                  // TODO(FUNCIONALIDADE): abrir DatePicker e salvar
                                  // a data selecionada no estado da OS.
                                },
                                icon: const Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ),
                          TextFormField(
                            initialValue: order?.deadline ?? '25/08/2026',
                            readOnly: true,
                            decoration: InputDecoration(
                              labelText: 'Prazo previsto *',
                              prefixIcon: const Icon(Icons.event_busy_outlined),
                              suffixIcon: IconButton(
                                tooltip: 'Selecionar prazo previsto',
                                onPressed: () {
                                  // TODO(FUNCIONALIDADE): abrir DatePicker e
                                  // atualizar o prazo da ordem.
                                },
                                icon: const Icon(Icons.calendar_month_outlined),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Diagnóstico e solução',
                  subtitle:
                      'Registre a análise técnica e a solução aplicada ao atendimento.',
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: order?.diagnosis,
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
                        initialValue: order?.solution,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Solução aplicada',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.task_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Peças, materiais e valores',
                  subtitle:
                      'A interface prevê mão de obra, peças e valor total da OS.',
                  child: Column(
                    children: [
                      _ResponsiveFields(
                        children: [
                          TextFormField(
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Valor da mão de obra',
                              prefixText: 'R\$ ',
                              prefixIcon: Icon(Icons.handyman_outlined),
                            ),
                          ),
                          TextFormField(
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
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
                          onPressed: () {
                            // TODO(FUNCIONALIDADE): abrir formulário para incluir
                            // descrição, quantidade e valor unitário de um item.
                          },
                          icon: const Icon(Icons.add_box_outlined),
                          label: const Text('Adicionar peça ou material'),
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
                              child: Text(
                                'Valor total da ordem',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Text(
                              order == null
                                  ? 'R\$ 0,00'
                                  : 'R\$ ${order.totalValue.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'DADO MOCKADO: o total acima não é recalculado pelos campos.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Imagens e evidências',
                  subtitle:
                      'Área visual para fotos antes/depois, defeitos e peças substituídas.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: const [
                          _EvidencePlaceholder(label: 'Antes da manutenção'),
                          _EvidencePlaceholder(label: 'Defeito encontrado'),
                          _EvidencePlaceholder(label: 'Após manutenção'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO(FUNCIONALIDADE): integrar câmera, galeria ou
                          // seletor de arquivos conforme a plataforma escolhida.
                        },
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Adicionar imagem'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        // TODO(FUNCIONALIDADE): validar campos obrigatórios,
                        // números, datas e vínculos; então cadastrar/atualizar a
                        // ordem por meio do controller/repository.
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(widget.isEditing
                          ? 'Salvar alterações'
                          : 'Salvar ordem'),
                    ),
                  ],
                ),
              ],
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
        final useColumns = constraints.maxWidth >= 760;
        if (!useColumns) {
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
              .map(
                (child) => SizedBox(
                  width: (constraints.maxWidth - 14) / 2,
                  child: child,
                ),
              )
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
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
