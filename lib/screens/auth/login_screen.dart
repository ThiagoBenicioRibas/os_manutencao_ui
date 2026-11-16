import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:os_manutencao_ui/controllers/identificacao_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _nomeFocus = FocusNode();

  @override
  void dispose() {
    _nomeController.dispose();
    _nomeFocus.dispose();
    super.dispose();
  }

  void _entrar() {
    if (!_formKey.currentState!.validate()) {
      _nomeFocus.requestFocus();
      return;
    }
    context.read<IdentificacaoController>().entrar(_nomeController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.build_circle_outlined,
                              size: 36,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Semantics(
                          header: true,
                          child: Text(
                            'Sistema de Ordem de Serviço',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Acesse para acompanhar clientes, equipamentos, técnicos e atendimentos.',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _nomeController,
                          focusNode: _nomeFocus,
                          autofocus: true,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          validator: IdentificacaoController.validarNome,
                          onFieldSubmitted: (_) => _entrar(),
                          decoration: const InputDecoration(
                            labelText: 'Nome',
                            hintText: 'Como você deseja ser identificado',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _entrar,
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar'),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Identificação local, sem senha. Informe seu nome a cada abertura do aplicativo.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
