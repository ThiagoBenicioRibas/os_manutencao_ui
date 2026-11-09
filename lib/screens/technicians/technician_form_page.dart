
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário de cadastro e edição de técnicos.
///
/// Preserva a estrutura visual original do professor
/// e utiliza o TecnicoController para salvar os dados.
class TechnicianFormPage extends StatefulWidget {
  const TechnicianFormPage({
    super.key,
    this.technician,
  });

  final Tecnico? technician;

  @override
  State<TechnicianFormPage> createState() =>
      _TechnicianFormPageState();
}

class _TechnicianFormPageState
    extends State<TechnicianFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nomeController;
  late final TextEditingController _contatoController;
  late final TextEditingController _especialidadeController;

  late String _situacao;

  bool _salvando = false;

  bool get _editando => widget.technician != null;

  @override
  void initState() {
    super.initState();

    final tecnico = widget.technician;

    _nomeController = TextEditingController(
      text: tecnico?.nome ?? '',
    );

    _contatoController = TextEditingController(
      text: tecnico?.contato ?? '',
    );

    _especialidadeController = TextEditingController(
      text: tecnico?.especialidade ?? '',
    );

    _situacao = tecnico?.situacao ?? 'Ativo';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _contatoController.dispose();
    _especialidadeController.dispose();

    super.dispose();
  }

  /// Valida os campos obrigatórios.
  String? _validarObrigatorio(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }

    return null;
  }

  /// Verifica se o contato possui um telefone válido.
  String? _validarContato(String? valor) {
    if (valor == null || valor.trim().isEmpty) {
      return 'Informe o contato do técnico.';
    }

    final digitos = valor.replaceAll(RegExp(r'\D'), '');

    if (digitos.length < 8) {
      return 'Informe um telefone válido.';
    }

    return null;
  }

  /// Valida os dados e salva o técnico no SQLite.
  Future<void> _salvarTecnico() async {
    if (_salvando) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _salvando = true;
    });

    final tecnico = Tecnico(
      id: widget.technician?.id,
      nome: _nomeController.text.trim(),
      contato: _contatoController.text.trim(),
      especialidade: _especialidadeController.text.trim(),
      situacao: _situacao,
    );

    try {
      final controlador = context.read<TecnicoController>();

      if (_editando) {
        await controlador.atualizar(tecnico);
      } else {
        await controlador.cadastrar(tecnico);
      }

      if (!mounted) {
        return;
      }

      // Informa à tela anterior que o registro foi salvo.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível salvar o técnico. '
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
          _editando ? 'Editar técnico' : 'Novo técnico',
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
                    title: 'Dados do profissional',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nomeController,
                          enabled: !_salvando,
                          textCapitalization:
                              TextCapitalization.words,
                          validator: _validarObrigatorio,
                          decoration: const InputDecoration(
                            labelText: 'Nome *',
                            prefixIcon:
                                Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _contatoController,
                          enabled: !_salvando,
                          keyboardType: TextInputType.phone,
                          validator: _validarContato,
                          decoration: const InputDecoration(
                            labelText: 'Contato *',
                            prefixIcon:
                                Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller:
                              _especialidadeController,
                          enabled: !_salvando,
                          validator: _validarObrigatorio,
                          decoration: const InputDecoration(
                            labelText: 'Especialidade *',
                            hintText:
                                'Ex.: climatização, informática, elétrica',
                            prefixIcon:
                                Icon(Icons.build_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _situacao,
                          decoration: const InputDecoration(
                            labelText:
                                'Situação do profissional *',
                            prefixIcon:
                                Icon(Icons.toggle_on_outlined),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Ativo',
                              child: Text('Ativo'),
                            ),
                            DropdownMenuItem(
                              value: 'Inativo',
                              child: Text('Inativo'),
                            ),
                          ],
                          onChanged: _salvando
                              ? null
                              : (valor) {
                                  if (valor != null) {
                                    setState(() {
                                      _situacao = valor;
                                    });
                                  }
                                },
                          validator: (valor) {
                            if (valor == null ||
                                valor.isEmpty) {
                              return 'Selecione a situação.';
                            }
                            return null;
                          },
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
                            _salvando ? null : _salvarTecnico,
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
                                  : 'Salvar técnico',
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
