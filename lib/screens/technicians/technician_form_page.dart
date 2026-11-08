import 'package:flutter/material.dart';
import 'package:os_manutencao_ui/core/mock_data.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Formulário visual de técnico.
class TechnicianFormPage extends StatefulWidget {
  const TechnicianFormPage({super.key, this.technician});

  final MockEntityData? technician;

  @override
  State<TechnicianFormPage> createState() => _TechnicianFormPageState();
}

class _TechnicianFormPageState extends State<TechnicianFormPage> {
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.technician?.status ?? 'Ativo';
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.technician != null;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Editar técnico' : 'Novo técnico')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionCard(
                  title: 'Dados do profissional',
                  child: Column(
                    children: [
                      TextFormField(
                        initialValue: widget.technician?.title,
                        decoration: const InputDecoration(
                          labelText: 'Nome *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Contato *',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Especialidade *',
                          hintText: 'Ex.: climatização, informática, elétrica',
                          prefixIcon: Icon(Icons.build_outlined),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _status,
                        decoration: const InputDecoration(
                          labelText: 'Situação do profissional *',
                          prefixIcon: Icon(Icons.toggle_on_outlined),
                        ),
                        items: const ['Ativo', 'Inativo']
                            .map((item) => DropdownMenuItem(
                                value: item, child: Text(item)))
                            .toList(),
                        onChanged: (value) {
                          // UI APENAS: altera somente o estado visual do campo.
                          if (value != null) {
                            setState(() => _status = value);
                          }
                          // TODO(FUNCIONALIDADE): persistir a situação e impedir
                          // atribuição de técnicos inativos, se essa regra for usada.
                        },
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
                        // TODO(FUNCIONALIDADE): validar e cadastrar/atualizar o técnico.
                      },
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                          editing ? 'Salvar alterações' : 'Salvar técnico'),
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
