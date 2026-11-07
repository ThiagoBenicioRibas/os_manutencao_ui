import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/screens/clients/client_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem visual de clientes.
class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

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
                title: 'Clientes',
                subtitle: 'Cadastre e consulte os responsáveis pelos equipamentos atendidos.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ClientFormPage()),
                      );
                    },
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Novo cliente'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SectionCard(
                title: 'Localizar cliente',
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Buscar cliente',
                    hintText: 'Nome, CPF/CNPJ, telefone ou e-mail',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    // TODO(FUNCIONALIDADE): filtrar os clientes reais no
                    // controller/repository conforme o texto informado.
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '${MockData.clients.length} clientes demonstrativos',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              ...MockData.clients.map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntityListCard(
                    title: client.title,
                    subtitle: client.subtitle,
                    details: client.details,
                    leadingIcon: Icons.business_outlined,
                    onEdit: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClientFormPage(client: client),
                        ),
                      );
                    },
                    onDelete: () => _showDeleteDialog(context, client.title),
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
        title: const Text('Excluir cliente?'),
        content: Text(
          'Confirma a exclusão de $name? Nesta interface demonstrativa nenhum dado será removido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              // TODO(FUNCIONALIDADE): verificar se o cliente possui equipamentos
              // ou ordens relacionadas e tratar a exclusão sem inconsistências.
              Navigator.of(context).pop();
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );
  }
}
