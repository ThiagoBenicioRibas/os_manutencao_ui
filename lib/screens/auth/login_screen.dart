import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/screens/app_shell.dart';

/// Tela inicial de acesso/identificação.
///
/// UI APENAS: os campos existem visualmente, mas não autenticam ninguém.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            Icons.build_circle_outlined,
                            size: 36,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Semantics(
                        header: true,
                        child: Text(
                          'Sistema de Ordem de Serviço',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Acesse para acompanhar clientes, equipamentos, técnicos e atendimentos.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const TextField(
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'E-mail ou identificação',
                          hintText: 'nome@empresa.com',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                            onPressed: () {
                              // UI APENAS: altera somente a visibilidade local do campo.
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO(FUNCIONALIDADE): implementar recuperação de acesso,
                            // caso esse recurso faça parte da solução escolhida.
                          },
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () {
                          // TODO(FUNCIONALIDADE): validar os campos e autenticar o
                          // usuário. Este botão propositalmente não faz login.
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('Entrar'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // UI APENAS: esta navegação existe para que o professor e
                          // o aluno possam visualizar o restante do protótipo sem
                          // depender de autenticação implementada.
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AppShell()),
                          );
                        },
                        icon: const Icon(Icons.preview_outlined),
                        label: const Text('Visualizar interface sem autenticação'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Protótipo acadêmico • dados demonstrativos',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    );
  }
}
