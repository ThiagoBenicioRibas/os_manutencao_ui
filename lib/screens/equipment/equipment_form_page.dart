import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário visual de equipamento/ativo.
class EquipmentFormPage extends StatefulWidget {
  const EquipmentFormPage({super.key, this.equipment});

  final MockEntityData? equipment;

  @override
  State<EquipmentFormPage> createState() => _EquipmentFormPageState();
}

class _EquipmentFormPageState extends State<EquipmentFormPage> {
  String _client = 'Clínica Horizonte';

  @override
  Widget build(BuildContext context) {
    final editing = widget.equipment != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar equipamento' : 'Novo equipamento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Identificação do equipamento',
                  subtitle:
                      'Cada equipamento deve ficar associado a um cliente.',
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _client,
                        decoration: const InputDecoration(
                          labelText: 'Cliente proprietário *',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: const [
                          'Clínica Horizonte',
                          'Escritório Delta',
                          'Padaria Avenida',
                          'Condomínio Jardim Sul',
                        ]
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          // UI APENAS: preserva a seleção local do componente.
                          if (value != null) setState(() => _client = value);
                          // TODO(FUNCIONALIDADE): carregar clientes reais e salvar
                          // o vínculo no cadastro do equipamento.
                        },
                      ),
                      const SizedBox(height: 14),
                      _TwoColumns(
                        children: [
                          TextFormField(
                            initialValue: editing ? 'Ar-condicionado' : null,
                            decoration: const InputDecoration(
                              labelText: 'Tipo *',
                              prefixIcon: Icon(Icons.category_outlined),
                            ),
                          ),
                          TextFormField(
                            initialValue: editing ? 'LG' : null,
                            decoration: const InputDecoration(
                              labelText: 'Marca',
                              prefixIcon: Icon(Icons.sell_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _TwoColumns(
                        children: [
                          TextFormField(
                            initialValue:
                                editing ? 'Dual Inverter 24.000 BTU' : null,
                            decoration: const InputDecoration(
                              labelText: 'Modelo',
                              prefixIcon: Icon(Icons.view_in_ar_outlined),
                            ),
                          ),
                          TextFormField(
                            initialValue: editing ? 'LG24-998712' : null,
                            decoration: const InputDecoration(
                              labelText: 'Número de série',
                              prefixIcon: Icon(Icons.numbers_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        initialValue: editing ? 'CL-AR-04' : null,
                        decoration: const InputDecoration(
                          labelText: 'Patrimônio',
                          prefixIcon: Icon(Icons.qr_code_2_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        minLines: 3,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Observações',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
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
                        // TODO(FUNCIONALIDADE): validar campos obrigatórios,
                        // verificar o vínculo com o cliente e cadastrar/atualizar
                        // o equipamento por meio do controller/repository.
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                          editing ? 'Salvar alterações' : 'Salvar equipamento'),
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
