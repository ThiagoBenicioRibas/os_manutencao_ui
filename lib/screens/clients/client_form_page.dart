
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário de cadastro e edição de clientes.
///
/// Mantém a estrutura visual original e utiliza
/// o ClienteController para persistir os dados.
class ClientFormPage extends StatefulWidget {
  const ClientFormPage({super.key, this.client});

  final Cliente? client;

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _documentoController;
  late final TextEditingController _telefoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _enderecoController;

  bool _salvando = false;

  bool get _editando => widget.client != null;

  @override
  void initState() {
    super.initState();

    final cliente = widget.client;

    _nomeController = TextEditingController(
      text: cliente?.nome ?? '',
    );

    _documentoController = TextEditingController(
      text: cliente?.documento ?? '',
    );

    _telefoneController = TextEditingController(
      text: cliente?.telefone ?? '',
    );

    _emailController = TextEditingController(
      text: cliente?.email ?? '',
    );

    _enderecoController = TextEditingController(
      text: cliente?.endereco ?? '',
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _documentoController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _enderecoController.dispose();

    super.dispose();
  }

  /// Converte campos opcionais vazios para null.
  String? _textoOpcional(String texto) {
    final valor = texto.trim();
    return valor.isEmpty ? null : valor;
  }

  /// Valida campos obrigatórios.
  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  /// Valida o telefone informado.
  String? _validarTelefone(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o telefone.';
    }

    final digitos = valor.replaceAll(RegExp(r'\D'), '');

    if (digitos.length < 8) {
      return 'Informe um telefone válido.';
    }

    return null;
  }

  /// Valida o e-mail apenas quando preenchido.
  String? _validarEmail(String? valor) {
    final email = valor?.trim() ?? '';

    if (email.isEmpty) {
      return null;
    }

    final formatoEmail = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!formatoEmail.hasMatch(email)) {
      return 'Informe um e-mail válido.';
    }

    return null;
  }

  /// Valida e salva o cadastro no SQLite.
  Future<void> _salvarCliente() async {
    if (_salvando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    final cliente = Cliente(
      id: widget.client?.id,
      nome: _nomeController.text.trim(),
      documento: _documentoController.text.trim(),
      telefone: _telefoneController.text.trim(),
      email: _textoOpcional(_emailController.text),
      endereco: _textoOpcional(_enderecoController.text),
    );

    try {
      final controlador = context.read<ClienteController>();

      if (_editando) {
        await controlador.atualizar(cliente);
      } else {
        await controlador.cadastrar(cliente);
      }

      if (!mounted) {
        return;
      }

      // Informa à tela de listagem que o cadastro foi salvo.
      Navigator.of(context).pop(true);
    } catch (erro) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o cliente. '
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _editando ? 'Editar cliente' : 'Novo cliente',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    title: 'Dados do cliente',
                    subtitle:
                        'Campos previstos no enunciado acadêmico.',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          enabled: !_salvando,
                          textCapitalization: TextCapitalization.words,
                          validator: _validarObrigatorio,
                          decoration: const InputDecoration(
                            labelText: 'Nome / razão social *',
                            prefixIcon:
                                Icon(Icons.business_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _documentoController,
                          enabled: !_salvando,
                          validator: _validarObrigatorio,
                          decoration: const InputDecoration(
                            labelText:
                                'CPF, CNPJ ou identificação *',
                            prefixIcon:
                                Icon(Icons.badge_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _TwoColumns(
                          children: [
                            TextFormField(
                              controller: _telefoneController,
                              enabled: !_salvando,
                              keyboardType: TextInputType.phone,
                              validator: _validarTelefone,
                              decoration: const InputDecoration(
                                labelText: 'Telefone *',
                                prefixIcon:
                                    Icon(Icons.phone_outlined),
                              ),
                            ),
                            TextFormField(
                              controller: _emailController,
                              enabled: !_salvando,
                              keyboardType:
                                  TextInputType.emailAddress,
                              validator: _validarEmail,
                              decoration: const InputDecoration(
                                labelText: 'E-mail',
                                prefixIcon:
                                    Icon(Icons.email_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _enderecoController,
                          enabled: !_salvando,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Endereço',
                            alignLabelWithHint: true,
                            prefixIcon:
                                Icon(Icons.location_on_outlined),
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
                            _salvando ? null : _salvarCliente,
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
                                  : 'Salvar cliente',
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

/// Mantém o layout responsivo original do professor.
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
