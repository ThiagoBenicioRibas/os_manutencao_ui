import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/controllers/ordem_servico_controller.dart';
import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/screens/orders/order_details_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/order_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Consulta de ordens com dados reais e filtros locais.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _buscaController = TextEditingController();
  String _busca = '';
  String _status = 'Todos';
  String _prioridade = 'Todas';
  int _tecnicoId = 0; // Zero representa todos os técnicos.
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _carregar();
    });
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      await Future.wait([
        context.read<OrdemServicoController>().carregar(),
        context.read<ClienteController>().carregar(),
        context.read<EquipamentoController>().carregar(),
        context.read<TecnicoController>().carregar(),
      ]);
    } catch (_) {
      if (mounted) {
        setState(() => _erro = 'Não foi possível carregar as ordens de serviço.');
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirFormulario([OrdemServico? ordem]) async {
    final alterou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderFormPage(order: ordem)),
    );
    if (mounted && alterou == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ordem == null
              ? 'Ordem de serviço cadastrada com sucesso.'
              : 'Ordem de serviço atualizada com sucesso.'),
        ),
      );
    }
  }

  Future<void> _abrirDetalhes(OrdemServico ordem) async {
    final excluiu = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => OrderDetailsPage(order: ordem)),
    );
    if (mounted && excluiu == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ordem de serviço excluída com sucesso.')),
      );
    }
  }

  void _limparFiltros() {
    _buscaController.clear();
    setState(() {
      _busca = '';
      _status = 'Todos';
      _prioridade = 'Todas';
      _tecnicoId = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final clientes = context.watch<ClienteController>().clientes;
    final equipamentos = context.watch<EquipamentoController>().equipamentos;
    final tecnicos = context.watch<TecnicoController>().tecnicos;
    final ordens = context.watch<OrdemServicoController>().ordens;

    final nomesClientes = <int, String>{
      for (final cliente in clientes)
        if (cliente.id != null) cliente.id!: cliente.nome,
    };
    final equipamentosPorId = <int, Equipamento>{
      for (final equipamento in equipamentos)
        if (equipamento.id != null) equipamento.id!: equipamento,
    };
    final nomesTecnicos = <int, String>{
      for (final tecnico in tecnicos)
        if (tecnico.id != null) tecnico.id!: tecnico.nome,
    };

    String nomeEquipamento(int id) {
      final e = equipamentosPorId[id];
      if (e == null) return 'Equipamento não encontrado';
      return [e.tipo, e.marca, e.modelo]
          .whereType<String>()
          .where((parte) => parte.trim().isNotEmpty)
          .join(' — ');
    }

    final filtro = _busca.trim().toLowerCase();
    final filtradas = ordens.where((ordem) {
      if (_status != 'Todos' && ordem.status != _status) return false;
      if (_prioridade != 'Todas' && ordem.prioridade != _prioridade) return false;
      if (_tecnicoId > 0 && ordem.tecnicoId != _tecnicoId) return false;
      if (filtro.isEmpty) return true;
      return [
        ordem.codigo,
        nomesClientes[ordem.clienteId] ?? '',
        nomeEquipamento(ordem.equipamentoId),
        nomesTecnicos[ordem.tecnicoId] ?? 'Sem técnico atribuído',
      ].any((texto) => texto.toLowerCase().contains(filtro));
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Ordens de serviço',
                subtitle: 'Busque, filtre e acompanhe o ciclo de cada atendimento.',
                actions: [
                  FilledButton.icon(
                    onPressed: _carregando ? null : () => _abrirFormulario(),
                    icon: const Icon(Icons.add),
                    label: const Text('Nova OS'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Busca e filtros',
                subtitle: 'Pesquise os registros reais cadastrados no SQLite.',
                child: Column(
                  children: [
                    TextField(
                      controller: _buscaController,
                      decoration: const InputDecoration(
                        labelText: 'Buscar ordem de serviço',
                        hintText: 'Número, cliente, equipamento ou técnico',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (texto) => setState(() => _busca = texto),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(builder: (context, constraints) {
                      final filtros = <Widget>[
                        DropdownButtonFormField<String>(
                          key: ValueKey('status-$_status'),
                          initialValue: _status,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            'Todos', 'Aberta', 'Atribuída', 'Em atendimento',
                            'Aguardando peça', 'Concluída', 'Cancelada',
                          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (valor) {
                            if (valor != null) setState(() => _status = valor);
                          },
                        ),
                        DropdownButtonFormField<String>(
                          key: ValueKey('prioridade-$_prioridade'),
                          initialValue: _prioridade,
                          decoration: const InputDecoration(labelText: 'Prioridade'),
                          items: const ['Todas', 'Baixa', 'Média', 'Alta', 'Urgente']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (valor) {
                            if (valor != null) setState(() => _prioridade = valor);
                          },
                        ),
                        DropdownButtonFormField<int>(
                          key: ValueKey('tecnico-$_tecnicoId'),
                          initialValue: nomesTecnicos.containsKey(_tecnicoId) ? _tecnicoId : 0,
                          isExpanded: true,
                          decoration: const InputDecoration(labelText: 'Técnico'),
                          items: [
                            const DropdownMenuItem(value: 0, child: Text('Todos')),
                            for (final t in tecnicos)
                              if (t.id != null)
                                DropdownMenuItem(
                                  value: t.id!,
                                  child: Text(t.nome, overflow: TextOverflow.ellipsis),
                                ),
                          ],
                          onChanged: (valor) {
                            if (valor != null) setState(() => _tecnicoId = valor);
                          },
                        ),
                      ];
                      if (constraints.maxWidth >= 840) {
                        return Row(children: [
                          Expanded(child: filtros[0]),
                          const SizedBox(width: 12),
                          Expanded(child: filtros[1]),
                          const SizedBox(width: 12),
                          Expanded(child: filtros[2]),
                        ]);
                      }
                      return Column(children: [
                        filtros[0],
                        const SizedBox(height: 12),
                        filtros[1],
                        const SizedBox(height: 12),
                        filtros[2],
                      ]);
                    }),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          TextButton.icon(
                            onPressed: _limparFiltros,
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Limpar filtros'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: _carregando ? null : _carregar,
                            icon: const Icon(Icons.filter_alt_outlined),
                            label: const Text('Aplicar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_carregando) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 12),
                const Text('Carregando ordens de serviço...'),
              ] else if (_erro != null) ...[
                Text(_erro!),
                TextButton.icon(
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ] else ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    '${filtradas.length} ordens de serviço encontradas',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                if (filtradas.isEmpty)
                  const Text('Nenhuma ordem encontrada para os filtros selecionados.'),
                ...filtradas.map((ordem) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: OrderCard(
                        order: ordem,
                        cliente: nomesClientes[ordem.clienteId] ?? 'Cliente não encontrado',
                        equipamento: nomeEquipamento(ordem.equipamentoId),
                        tecnico: nomesTecnicos[ordem.tecnicoId] ?? 'Sem técnico atribuído',
                        onView: () => _abrirDetalhes(ordem),
                        onEdit: () => _abrirFormulario(ordem),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
