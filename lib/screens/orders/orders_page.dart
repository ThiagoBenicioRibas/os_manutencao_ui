import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/screens/orders/order_details_page.dart';
import 'package:os_manutencao_ui/screens/orders/order_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/order_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Tela de consulta das ordens de serviço.
///
/// A busca e os filtros estão presentes visualmente, porém não alteram a lista.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String _status = 'Todos';
  String _priority = 'Todas';
  String _technician = 'Todos';

  @override
  Widget build(BuildContext context) {
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
                subtitle:
                    'Busque, filtre e acompanhe o ciclo de cada atendimento.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const OrderFormPage()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Nova OS'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Busca e filtros',
                subtitle:
                    'Os controles abaixo são somente visuais nesta entrega.',
                child: Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar ordem de serviço',
                        hintText: 'Número, cliente, equipamento ou técnico',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        // TODO(FUNCIONALIDADE): encaminhar o texto para o
                        // controller/viewmodel e filtrar a coleção de ordens.
                      },
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final wide = constraints.maxWidth >= 840;
                        final filters = <Widget>[
                          DropdownButtonFormField<String>(
                            initialValue: _status,
                            decoration:
                                const InputDecoration(labelText: 'Status'),
                            items: const [
                              'Todos',
                              'Aberta',
                              'Atribuída',
                              'Em atendimento',
                              'Aguardando peça',
                              'Concluída',
                              'Cancelada',
                            ]
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              // UI APENAS: preserva a seleção do controle.
                              // TODO(FUNCIONALIDADE): aplicar o filtro nos dados reais.
                              if (value != null) {
                                setState(() => _status = value);
                              }
                            },
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _priority,
                            decoration:
                                const InputDecoration(labelText: 'Prioridade'),
                            items: const [
                              'Todas',
                              'Baixa',
                              'Média',
                              'Alta',
                              'Urgente'
                            ]
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              // UI APENAS: preserva a seleção do controle.
                              // TODO(FUNCIONALIDADE): aplicar o filtro nos dados reais.
                              if (value != null) {
                                setState(() => _priority = value);
                              }
                            },
                          ),
                          DropdownButtonFormField<String>(
                            initialValue: _technician,
                            decoration:
                                const InputDecoration(labelText: 'Técnico'),
                            items: const [
                              'Todos',
                              'Carlos Almeida',
                              'Fernanda Souza',
                              'Rafael Martins',
                            ]
                                .map((item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              // UI APENAS: preserva a seleção do controle.
                              // TODO(FUNCIONALIDADE): aplicar o filtro nos dados reais.
                              if (value != null) {
                                setState(() => _technician = value);
                              }
                            },
                          ),
                        ];

                        if (wide) {
                          return Row(
                            children: [
                              Expanded(child: filters[0]),
                              const SizedBox(width: 12),
                              Expanded(child: filters[1]),
                              const SizedBox(width: 12),
                              Expanded(child: filters[2]),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            filters[0],
                            const SizedBox(height: 12),
                            filters[1],
                            const SizedBox(height: 12),
                            filters[2],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // UI APENAS: limpa somente as seleções locais.
                              setState(() {
                                _status = 'Todos';
                                _priority = 'Todas';
                                _technician = 'Todos';
                              });
                              // TODO(FUNCIONALIDADE): também limpar a busca e o
                              // estado de filtros do controller/viewmodel real.
                            },
                            icon: const Icon(Icons.filter_alt_off_outlined),
                            label: const Text('Limpar filtros'),
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              // TODO(FUNCIONALIDADE): executar a consulta filtrada.
                            },
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
              Text(
                '${MockData.orders.length} ordens demonstrativas',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...MockData.orders.map(
                (order) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OrderCard(
                    order: order,
                    onView: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsPage(order: order),
                        ),
                      );
                    },
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => OrderFormPage(order: order),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
