import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/app_theme.dart';
import 'package:os_manutencao_ui/screens/auth/login_screen.dart';

/// Ponto de entrada do protótipo visual.
///
/// IMPORTANTE: este projeto foi criado para conter somente a interface.
/// Todas as integrações reais estão marcadas com TODO(FUNCIONALIDADE).
///
void main() {
  runApp(const OrdemServicoUiApp());
}

/// MaterialApp principal.
///
/// TODO(FUNCIONALIDADE): caso o aluno implemente tema escuro persistente,
/// autenticação, rotas nomeadas ou injeção de dependências, este é um dos
/// pontos adequados para conectar essas estruturas.
class OrdemServicoUiApp extends StatelessWidget {
  const OrdemServicoUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OS Manutenção',
      theme: AppTheme.light,
      home: const LoginScreen(),
    );
  }
}
