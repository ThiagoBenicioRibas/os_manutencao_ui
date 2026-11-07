import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/screens/technicians/technician_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem visual de técnicos responsáveis pelos atendimentos.
class TechniciansPage extends StatelessWidget {
  const TechniciansPage({super.key});

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
                title: 'Técnicos',
                subtitle: 'Profissionais disponíveis para atribuição nas ordens de serviço.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TechnicianFormPage()),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_outlined),
                    label: const Text('Novo técnico'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Localizar técnico',
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar técnico',
                    hintText: 'Nome, contato ou especialidade',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO(FUNCIONALIDADE): pesquisar técnicos reais.
                  },
                ),
              ),
              const SizedBox(height: 20),
              ...MockData.technicians.map(
                (technician) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntityListCard(
                    title: technician.title,
                    subtitle: technician.subtitle,
                    details: technician.details,
                    status: technician.status,
                    leadingIcon: Icons.engineering_outlined,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TechnicianFormPage(technician: technician),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteDialog(context, technician.title),
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
        title: const Text('Excluir técnico?'),
        content: Text(
          'Confirma a exclusão de $name? A interface não removerá nenhum dado nesta versão.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // TODO(FUNCIONALIDADE): validar vínculos com ordens e permissões
              // antes da exclusão real.
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
  }
}
