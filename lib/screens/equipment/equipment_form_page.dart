
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário de cadastro e edição de equipamentos.
///
/// Preserva a estrutura visual original do professor
/// e conecta os equipamentos aos clientes reais do SQLite.
class EquipmentFormPage extends StatefulWidget {
  const EquipmentFormPage({
    super.key,
    this.equipment,
  });

  final Equipamento? equipment;

  @override
  State<EquipmentFormPage> createState() =>
      _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _tipoController;
  late final TextEditingController _marcaController;
  late final TextEditingController _modeloController;
  late final TextEditingController _serieController;
  late final TextEditingController _patrimonioController;
  late final TextEditingController _observacoesController;

  int? _clienteIdSelecionado;

  bool _carregandoClientes = true;
  bool _salvando = false;
  String? _erroClientes;

  bool get _editando => widget.equipment != null;

  @override
  void initState() {
    super.initState();

    final equipamento = widget.equipment;

    _clienteIdSelecionado = equipamento?.clienteId;

    _tipoController = TextEditingController(
      text: equipamento?.tipo ?? '',
    );

    _marcaController = TextEditingController(
      text: equipamento?.marca ?? '',
    );

    _modeloController = TextEditingController(
      text: equipamento?.modelo ?? '',
    );

    _serieController = TextEditingController(
      text: equipamento?.numeroSerie ?? '',
    );

    _patrimonioController = TextEditingController(
      text: equipamento?.patrimonio ?? '',
    );

    _observacoesController = TextEditingController(
      text: equipamento?.observacoes ?? '',
    );

    // Busca os clientes reais após a construção inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarClientes();
      }
    });
  }

  @override
  void dispose() {
    _tipoController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    _patrimonioController.dispose();
    _observacoesController.dispose();

    super.dispose();
  }

  /// Consulta os clientes disponíveis no SQLite.
  Future<void> _carregarClientes() async {
    setState(() {
      _carregandoClientes = true;
      _erroClientes = null;
    });

    try {
      await context.read<ClienteController>().carregar();
    } catch (_) {
      if (mounted) {
        setState(() {
          _erroClientes =
              'Não foi possível carregar os clientes cadastrados.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _carregandoClientes = false;
        });
      }
    }
  }

  /// Valida os campos obrigatórios.
  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  /// Converte campos opcionais vazios para null.
  String? _textoOpcional(String texto) {
    final valor = texto.trim();

    return valor.isEmpty ? null : valor;
  }

  /// Valida e salva o equipamento no SQLite.
  Future<void> _salvarEquipamento() async {
    if (_salvando || _carregandoClientes) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final clienteId = _clienteIdSelecionado;

    if (clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecione o cliente proprietário do equipamento.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _salvando = true;
    });

    final equipamento = Equipamento(
      id: widget.equipment?.id,
      clienteId: clienteId,
      tipo: _tipoController.text.trim(),
      marca: _textoOpcional(_marcaController.text),
      modelo: _textoOpcional(_modeloController.text),
      numeroSerie: _textoOpcional(_serieController.text),
      patrimonio: _textoOpcional(_patrimonioController.text),
      observacoes: _textoOpcional(
        _observacoesController.text,
      ),
    );

    try {
      final controlador = context.read<EquipamentoController>();

      if (_editando) {
        await controlador.atualizar(equipamento);
      } else {
        await controlador.cadastrar(equipamento);
      }

      if (!mounted) {
        return;
      }

      // Retorna à listagem informando que salvou.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o equipamento. '
            'Verifique os dados e tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteController>().clientes;

    final clienteSelecionadoExiste = clientes.any(
      (cliente) => cliente.id == _clienteIdSelecionado,
    );

    final podeSalvar = !_salvando &&
        !_carregandoClientes &&
        _erroClientes == null &&
        clientes.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar equipamento' : 'Novo equipamento',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: 'Identificação do equipamento',
                    subtitle:
                        'Cada equipamento deve ficar associado a um cliente.',
                    child: Column(
                      children: [
                        // Carregamento dos clientes reais.
                        if (_carregandoClientes) ...[
                          const LinearProgressIndicator(),
                          const SizedBox(height: 12),
                          const Text(
                            'Carregando clientes cadastrados...',
                          ),
                        ] else if (_erroClientes != null) ...[
                          Text(_erroClientes!),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _carregarClientes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Tentar novamente'),
                          ),
                        ] else ...[
                          if (clientes.isEmpty) ...[
                            const Text(
                              'Nenhum cliente cadastrado. '
                              'Cadastre um cliente na aba Clientes '
                              'antes de salvar um equipamento.',
                            ),
                            const SizedBox(height: 12),
                          ],
                          DropdownButtonFormField<int>(
                            initialValue: clienteSelecionadoExiste
                                ? _clienteIdSelecionado
                                : null,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Cliente proprietário *',
                              prefixIcon:
                                  Icon(Icons.business_outlined),
                            ),
                            items: [
                              for (final cliente in clientes)
                                if (cliente.id != null)
                                  DropdownMenuItem<int>(
                                    value: cliente.id!,
                                    child: Text(
                                      cliente.nome,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                            ],
                            onChanged: _salvando || clientes.isEmpty
                                ? null
                                : (valor) {
                                    setState(() {
                                      _clienteIdSelecionado = valor;
                                    });
                                  },
                            validator: (valor) {
                              if (valor == null) {
                                return 'Selecione um cliente.';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 14),
                        _TwoColumns(
                          children: [
                            TextFormField(
                              controller: _tipoController,
                              enabled: !_salvando,
                              validator: _validarObrigatorio,
                              decoration: const InputDecoration(
                                labelText: 'Tipo *',
                                prefixIcon:
                                    Icon(Icons.category_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _marcaController,
                              enabled: !_salvando,
                              decoration: const InputDecoration(
                                labelText: 'Marca',
                                prefixIcon:
                                    Icon(Icons.sell_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _TwoColumns(
                          children: [
                            TextFormField(
                              controller: _modeloController,
                              enabled: !_salvando,
                              decoration: const InputDecoration(
                                labelText: 'Modelo',
                                prefixIcon:
                                    Icon(Icons.view_in_ar_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _serieController,
                              enabled: !_salvando,
                              decoration: const InputDecoration(
                                labelText: 'Número de série',
                                prefixIcon:
                                    Icon(Icons.numbers_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _patrimonioController,
                          enabled: !_salvando,
                          decoration: const InputDecoration(
                            labelText: 'Patrimônio',
                            prefixIcon:
                                Icon(Icons.qr_code_2_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _observacoesController,
                          enabled: !_salvando,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            alignLabelWithHint: true,
                            prefixIcon:
                                Icon(Icons.notes_outlined),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _salvando
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed:
                            podeSalvar ? _salvarEquipamento : null,
                        icon: _salvando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _salvando
                              ? 'Salvando...'
                              : _editando
                                  ? 'Salvar alterações'
                                  : 'Salvar equipamento',
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

/// Mantém a disposição responsiva original do professor.
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: [
              children[0],
              const SizedBox(height: 14),
              children[1],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 14),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}
