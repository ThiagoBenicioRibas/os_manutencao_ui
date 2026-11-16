import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:os_manutencao_ui/controllers/identificacao_controller.dart';
import 'package:os_manutencao_ui/screens/clients/clients_page.dart';
import 'package:os_manutencao_ui/screens/dashboard/dashboard_page.dart';
import 'package:os_manutencao_ui/screens/equipment/equipment_page.dart';
import 'package:os_manutencao_ui/screens/orders/orders_page.dart';
import 'package:os_manutencao_ui/screens/technicians/technicians_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  static const _pages = <Widget>[
    DashboardPage(),
    OrdersPage(),
    ClientsPage(),
    TechniciansPage(),
    EquipmentPage(),
  ];

  static const _destinations = <_Destination>[
    _Destination('Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _Destination(
        'Ordens de serviço', Icons.assignment_outlined, Icons.assignment),
    _Destination('Clientes', Icons.people_outline, Icons.people),
    _Destination('Técnicos', Icons.engineering_outlined, Icons.engineering),
    _Destination('Equipamentos', Icons.precision_manufacturing_outlined,
        Icons.precision_manufacturing),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 980;
        final extendedRail = constraints.maxWidth >= 1220;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OS Manutenção'),
                Text(
                  'Identificação: ${context.watch<IdentificacaoController>().nome}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Ajuda sobre a interface',
                onPressed: () => _showAboutDialog(context),
                icon: const Icon(Icons.help_outline),
              ),
              IconButton(
                tooltip: 'Sair',
                onPressed: () {
                  context.read<IdentificacaoController>().sair();
                },
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 8),
            ],
          ),
          drawer: desktop ? null : _buildDrawer(),
          body: Row(
            children: [
              if (desktop)
                NavigationRail(
                  extended: extendedRail,
                  selectedIndex: _selectedIndex,
                  labelType: extendedRail
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  leading: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Icon(
                      Icons.handyman_outlined,
                      size: 32,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
              Expanded(
                child: FocusTraversalGroup(
                  child: _pages[_selectedIndex],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        Navigator.of(context).pop();
      },
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(28, 24, 16, 12),
          child: Text(
            'Navegação',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        ..._destinations.map(
          (item) => NavigationDrawerDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: Text(item.label),
          ),
        ),
      ],
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sobre o aplicativo'),
        content: const Text(
          'Gerencie clientes, técnicos, equipamentos e ordens de serviço com dados salvos neste computador. '
          'O Dashboard resume os atendimentos registrados. '
          'A identificação local usa o nome informado durante esta sessão. '
          'Use Sair para encerrar a sessão e informar outro nome.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
