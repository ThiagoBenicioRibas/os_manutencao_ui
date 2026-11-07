import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário visual para cadastro/edição de cliente.
class ClientFormPage extends StatelessWidget {
  const ClientFormPage({super.key, this.client});

  final MockEntityData? client;

  @override
  Widget build(BuildContext context) {
    final editing = client != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar cliente' : 'Novo cliente')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Dados do cliente',
                  subtitle: 'Campos previstos no enunciado acadêmico.',
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: client?.title,
                        decoration: const InputDecoration(
                          labelText: 'Nome / razão social *',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'CPF, CNPJ ou identificação *',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _TwoColumns(
                        children: [
                          TextFormField(
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Telefone *',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          TextFormField(
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'E-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        minLines: 2,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Endereço',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () {
                        // TODO(FUNCIONALIDADE): validar obrigatórios, e-mail e
                        // telefone; depois cadastrar ou atualizar o cliente.
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                          editing ? 'Salvar alterações' : 'Salvar cliente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: [children[0], const SizedBox(height: 14), children[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: children[0]),
            const SizedBox(width: 14),
            Expanded(child: children[1]),
          ],
        );
      },
    );
  }
}
