import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/screens/equipment/equipment_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem visual dos equipamentos/ativos vinculados aos clientes.
class EquipmentPage extends StatelessWidget {
  const EquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppPageHeader(
                title: 'Equipamentos',
                subtitle: 'Ativos vinculados aos clientes e utilizados nas ordens de serviço.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EquipmentFormPage()),
                      );
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Novo equipamento'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Localizar equipamento',
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar equipamento',
                    hintText: 'Tipo, marca, modelo, série, patrimônio ou cliente',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO(FUNCIONALIDADE): consultar os equipamentos reais e
                    // atualizar a listagem conforme a busca.
                  },
                ),
              ),
              const SizedBox(height: 20),
              ...MockData.equipments.map(
                (equipment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntityListCard(
                    title: equipment.title,
                    subtitle: equipment.subtitle,
                    details: equipment.details,
                    leadingIcon: Icons.precision_manufacturing_outlined,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EquipmentFormPage(equipment: equipment),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteDialog(context, equipment.title),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String name) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir equipamento?'),
        content: Text(
          'Confirma a exclusão de $name? Nesta versão visual nenhum dado será removido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // TODO(FUNCIONALIDADE): impedir ou tratar exclusão quando houver
              // ordens de serviço relacionadas a este equipamento.
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
  }
}
