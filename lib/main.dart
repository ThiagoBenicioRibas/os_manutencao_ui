
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/historico_status_controller.dart';
import 'package:os_manutencao_ui/controllers/item_utilizado_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';

import 'package:os_manutencao_ui/core/app_theme.dart';
import 'package:os_manutencao_ui/screens/auth/login_screen.dart';

/// Ponto de entrada do aplicativo de ordens de serviço.
///
/// A interface original é preservada. Os controladores
/// ficam disponíveis para a integração com o SQLite.
void main() {
  runApp(const OrdemServicoUiApp());
}

/// Aplicativo principal.
///
/// O MultiProvider disponibiliza os controladores
/// para as telas e gerencia seu ciclo de vida.
class OrdemServicoUiApp extends StatelessWidget {
  const OrdemServicoUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ClienteController>(
          create: (_) => ClienteController(),
        ),
        ChangeNotifierProvider<TecnicoController>(
          create: (_) => TecnicoController(),
        ),
        ChangeNotifierProvider<EquipamentoController>(
          create: (_) => EquipamentoController(),
        ),
        ChangeNotifierProvider<OrdemServicoController>(
          create: (_) => OrdemServicoController(),
        ),
        ChangeNotifierProvider<ItemUtilizadoController>(
          create: (_) => ItemUtilizadoController(),
        ),
        ChangeNotifierProvider<HistoricoStatusController>(
          create: (_) => HistoricoStatusController(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'OS Manutenção',
        theme: AppTheme.light,
        home: const LoginScreen(),
      ),
    );
  }
}
