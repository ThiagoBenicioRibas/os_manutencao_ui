
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formata um valor em centavos para apresentação em reais.
String _formatarReais(int centavos) {
  final reais = centavos ~/ 100;
  final parteDecimal = (centavos % 100).toString().padLeft(2, '0');

  return 'R\$ $reais,$parteDecimal';
}

/// Formata um valor em centavos para um campo de edição.
String _formatarValorEditavel(int centavos) {
  final reais = centavos ~/ 100;
  final parteDecimal = (centavos % 100).toString().padLeft(2, '0');

  return '$reais,$parteDecimal';
}

/// Dados validados pelo formulário de peças e materiais.
class _DadosItem {
  const _DadosItem({
    required this.descricao,
    required this.quantidade,
    required this.valorUnitarioCentavos,
  });

  final String descricao;
  final int quantidade;
  final int valorUnitarioCentavos;
}

/// Tela de gerenciamento dos materiais utilizados em uma OS.
///
/// Utiliza o controlador e o repositório SQLite já existentes.
class OrderItemsPage extends StatefulWidget {
  const OrderItemsPage({
    super.key,
    required this.ordemId,
    required this.codigo,
  });

  final int ordemId;
  final String codigo;

  @override
  State<OrderItemsPage> createState() => _OrderItemsPageState();
}

class _OrderItemsPageState extends State<OrderItemsPage> {
  bool _processando = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarItens();
      }
    });
  }

  /// Consulta os materiais da Ordem de Serviço selecionada.
  Future<void> _carregarItens() async {
    try {
      await context
          .read<ItemUtilizadoController>()
          .carregarPorOrdem(widget.ordemId);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível carregar os materiais da ordem.',
          ),
        ),
      );
    }
  }

  /// Abre o formulário para cadastrar ou editar um material.
  Future<void> _abrirFormulario([ItemUtilizado? item]) async {
    if (_processando) {
      return;
    }

    final dados = await showDialog<_DadosItem>(
      context: context,
      builder: (_) => _ItemFormDialog(item: item),
    );

    if (!mounted || dados == null) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      final controlador = context.read<ItemUtilizadoController>();

      final novoItem = ItemUtilizado(
        id: item?.id,
        ordemId: widget.ordemId,
        descricao: dados.descricao,
        quantidade: dados.quantidade,
        valorUnitarioCentavos: dados.valorUnitarioCentavos,
      );

      if (item == null) {
        await controlador.cadastrar(novoItem);
      } else {
        await controlador.atualizar(novoItem);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            item == null
                ? 'Material cadastrado com sucesso.'
                : 'Material atualizado com sucesso.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o material.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  /// Solicita confirmação antes de excluir um material.
  Future<void> _excluirItem(ItemUtilizado item) async {
    if (_processando || item.id == null) {
      return;
    }

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir material?'),
        content: Text(
          'Deseja excluir "${item.descricao}" desta '
          'Ordem de Serviço? Esta ação não pode ser desfeita.',
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

    if (!mounted || confirmou != true) {
      return;
    }

    setState(() {
      _processando = true;
    });

    try {
      await context
          .read<ItemUtilizadoController>()
          .excluir(item.id!);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Material excluído com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir o material.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controlador = context.watch<ItemUtilizadoController>();

    // Garante que somente os materiais desta OS sejam exibidos.
    final itens = controlador.itens
        .where((item) => item.ordemId == widget.ordemId)
        .toList();

    // Utiliza os subtotais calculados pelo modelo existente.
    final totalCentavos = itens.fold<int>(
      0,
      (total, item) => total + item.subtotalCentavos,
    );

    final ocupado = _processando || controlador.carregando;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peças e materiais'),
        actions: [
          IconButton(
            tooltip: 'Atualizar lista de materiais',
            onPressed: ocupado ? null : _carregarItens,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Ordem de Serviço',
                  child: Text(widget.codigo),
                ),
                const SizedBox(height: 16),

                SectionCard(
                  title: 'Materiais utilizados',
                  subtitle:
                      'Cadastre as peças e os materiais empregados '
                      'no atendimento.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.icon(
                          onPressed: ocupado
                              ? null
                              : () => _abrirFormulario(),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar material'),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (controlador.carregando)
                        const Center(
                          child: CircularProgressIndicator(),
                        )
                      else if (controlador.erro != null)
                        Text(controlador.erro!)
                      else if (itens.isEmpty)
                        const Text(
                          'Nenhum material cadastrado para esta '
                          'Ordem de Serviço.',
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in itens) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.descricao,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Quantidade: ${item.quantidade}',
                                      ),
                                      Text(
                                        'Valor unitário: '
                                        '${_formatarReais(
                                          item.valorUnitarioCentavos,
                                        )}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Subtotal: '
                                        '${_formatarReais(
                                          item.subtotalCentavos,
                                        )}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: ocupado
                                                ? null
                                                : () =>
                                                    _abrirFormulario(item),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            label: Text(
                                              'Editar ${item.descricao}',
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: ocupado
                                                ? null
                                                : () => _excluirItem(item),
                                            icon: const Icon(
                                              Icons.delete_outline,
                                            ),
                                            label: Text(
                                              'Excluir ${item.descricao}',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                SectionCard(
                  title: 'Resumo dos materiais',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantidade de materiais cadastrados: '
                        '${itens.length}',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Total de peças e materiais: '
                        '${_formatarReais(totalCentavos)}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulário utilizado para cadastrar e editar materiais.
class _ItemFormDialog extends StatefulWidget {
  const _ItemFormDialog({
    this.item,
  });

  final ItemUtilizado? item;

  @override
  State<_ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<_ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _descricaoController;
  late final TextEditingController _quantidadeController;
  late final TextEditingController _valorController;

  @override
  void initState() {
    super.initState();

    final item = widget.item;

    _descricaoController = TextEditingController(
      text: item?.descricao ?? '',
    );

    _quantidadeController = TextEditingController(
      text: item?.quantidade.toString() ?? '1',
    );

    _valorController = TextEditingController(
      text: item == null
          ? ''
          : _formatarValorEditavel(item.valorUnitarioCentavos),
    );
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _quantidadeController.dispose();
    _valorController.dispose();
    super.dispose();
  }

  /// Converte o valor informado para centavos, sem arredondamentos.
  ///
  /// Aceita, por exemplo, 50, 50,5 e 50,50.
  int? _converterValorCentavos(String texto) {
    final valor = texto.trim();

    if (!RegExp(r'^\d+([,.]\d{1,2})?$').hasMatch(valor)) {
      return null;
    }

    final partes = valor.replaceAll('.', ',').split(',');

    final reais = int.tryParse(partes.first);

    final centavos = partes.length == 1
        ? 0
        : int.tryParse(partes.last.padRight(2, '0'));

    if (reais == null || centavos == null) {
      return null;
    }

    // Evita valores excessivamente grandes no SQLite.
    if (reais > 99999999) {
      return null;
    }

    return reais * 100 + centavos;
  }

  void _confirmar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quantidade = int.parse(
      _quantidadeController.text.trim(),
    );

    final valorCentavos = _converterValorCentavos(
      _valorController.text,
    )!;

    Navigator.of(context).pop(
      _DadosItem(
        descricao: _descricaoController.text.trim(),
        quantidade: quantidade,
        valorUnitarioCentavos: valorCentavos,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.item == null
            ? 'Adicionar material'
            : 'Editar material',
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _descricaoController,
                  autofocus: true,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Descrição do material *',
                    hintText: 'Ex.: Fonte de alimentação',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (valor == null || valor.trim().isEmpty) {
                      return 'Informe a descrição do material.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantidadeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantidade *',
                    hintText: 'Ex.: 2',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    final quantidade = int.tryParse(
                      (valor ?? '').trim(),
                    );

                    if (quantidade == null || quantidade <= 0) {
                      return 'Informe uma quantidade inteira '
                          'maior que zero.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _valorController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor unitário em reais *',
                    hintText: 'Ex.: 25,50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (valor) {
                    if (_converterValorCentavos(valor ?? '') == null) {
                      return 'Informe um valor válido, como 25,50. '
                          'Não utilize separador de milhar.';
                    }

                    return null;
                  },
                ),
              ],
            ),
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
          onPressed: _confirmar,
          child: const Text('Salvar material'),
        ),
      ],
    );
  }
}
