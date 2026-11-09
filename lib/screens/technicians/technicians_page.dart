
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/tecnico_controller.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/screens/technicians/technician_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem de técnicos conectada ao SQLite.
///
/// Preserva a estrutura visual original do professor
/// e utiliza o TecnicoController para gerenciar os dados.
class TechniciansPage extends StatefulWidget {
  const TechniciansPage({super.key});

  @override
  State<TechniciansPage> createState() =>
      _TechniciansPageState();
}

class _TechniciansPageState extends State<TechniciansPage> {
  String _textoBusca = '';

  @override
  void initState() {
    super.initState();

    // Carrega os técnicos depois da primeira
    // construção da interface.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarTecnicos();
      }
    });
  }

  /// Consulta os técnicos cadastrados no SQLite.
  Future<void> _carregarTecnicos() async {
    try {
      await context.read<TecnicoController>().carregar();
    } catch (_) {
      // O controlador registra a falha e
      // notifica a interface automaticamente.
    }
  }

  /// Verifica se o técnico corresponde à pesquisa.
  bool _correspondeBusca(Tecnico tecnico) {
    final busca = _textoBusca.trim().toLowerCase();

    if (busca.isEmpty) {
      return true;
    }

    final campos = [
      tecnico.nome,
      tecnico.contato,
      tecnico.especialidade,
    ];

    return campos.any(
      (campo) => campo.toLowerCase().contains(busca),
    );
  }

  /// Abre o formulário para cadastrar ou editar.
  Future<void> _abrirFormulario({Tecnico? tecnico}) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => TechnicianFormPage(
          technician: tecnico,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (salvo == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tecnico == null
                ? 'Técnico cadastrado com sucesso.'
                : 'Técnico atualizado com sucesso.',
          ),
        ),
      );
    }
  }

  /// Solicita confirmação antes de excluir o técnico.
  Future<void> _confirmarExclusao(Tecnico tecnico) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir técnico?'),
        content: Text(
          'Confirma a exclusão de ${tecnico.nome}? '
          'Esta ação não poderá ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(false);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Confirmar exclusão'),
          ),
        ],
      ),
    );

    if (!mounted || confirmado != true) {
      return;
    }

    final id = tecnico.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o técnico.',
          ),
        ),
      );
      return;
    }

    try {
      await context.read<TecnicoController>().excluir(id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Técnico excluído com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir o técnico. '
            'Verifique se existem ordens de serviço '
            'vinculadas a ele.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // A interface acompanha as alterações do controlador.
    final controlador = context.watch<TecnicoController>();

    final tecnicosFiltrados = controlador.tecnicos
        .where(_correspondeBusca)
        .toList();

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
                subtitle:
                    'Profissionais disponíveis para atribuição '
                    'nas ordens de serviço.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      _abrirFormulario();
                    },
                    icon: const Icon(
                      Icons.person_add_alt_outlined,
                    ),
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
                  onChanged: (valor) {
                    setState(() {
                      _textoBusca = valor;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Exibe o progresso das operações.
              if (controlador.carregando) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // Exibe os erros registrados pelo controlador.
              if (controlador.erro != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Não foi possível concluir a operação.',
                        ),
                        const SizedBox(height: 8),
                        Text(controlador.erro!),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            _carregarTecnicos();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quantidade de registros encontrados.
              Text(
                _textoBusca.trim().isEmpty
                    ? '${controlador.tecnicos.length} técnicos cadastrados'
                    : '${tecnicosFiltrados.length} técnicos encontrados',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),

              // Mensagem para lista vazia ou busca sem resultados.
              if (!controlador.carregando &&
                  controlador.erro == null &&
                  tecnicosFiltrados.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _textoBusca.trim().isEmpty
                            ? 'Nenhum técnico cadastrado. '
                              'Utilize "Novo técnico" '
                              'para iniciar o cadastro.'
                            : 'Nenhum técnico encontrado '
                              'para a pesquisa informada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // Lista de técnicos cadastrados no SQLite.
              ...tecnicosFiltrados.map(
                (tecnico) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntityListCard(
                    title: tecnico.nome,
                    subtitle: 'Contato: ${tecnico.contato}',
                    details:
                        'Especialidade: ${tecnico.especialidade}',
                    status: tecnico.situacao,
                    leadingIcon: Icons.engineering_outlined,
                    onEdit: () {
                      _abrirFormulario(tecnico: tecnico);
                    },
                    onDelete: () {
                      _confirmarExclusao(tecnico);
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
