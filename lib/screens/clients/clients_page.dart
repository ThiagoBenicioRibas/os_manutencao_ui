
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/screens/clients/client_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem de clientes conectada ao banco SQLite.
///
/// Preserva a estrutura visual original do professor
/// e utiliza o ClienteController para consultar,
/// pesquisar, editar e excluir clientes.
class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String _textoBusca = '';

  @override
  void initState() {
    super.initState();

    // Aguarda a construção inicial da tela antes de
    // solicitar o carregamento dos dados.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarClientes();
      }
    });
  }

  /// Consulta os clientes cadastrados no SQLite.
  Future<void> _carregarClientes() async {
    try {
      await context.read<ClienteController>().carregar();
    } catch (_) {
      // O controlador já registra o erro e notifica
      // a interface para apresentar a mensagem.
    }
  }

  /// Verifica se o cliente corresponde ao texto pesquisado.
  bool _correspondeBusca(Cliente cliente) {
    final busca = _textoBusca.trim().toLowerCase();

    if (busca.isEmpty) {
      return true;
    }

    final campos = [
      cliente.nome,
      cliente.documento,
      cliente.telefone,
      cliente.email ?? '',
    ];

    return campos.any(
      (campo) => campo.toLowerCase().contains(busca),
    );
  }

  /// Monta as informações complementares do cliente.
  String _detalhesCliente(Cliente cliente) {
    final detalhes = <String>[];

    final email = cliente.email?.trim() ?? '';
    final endereco = cliente.endereco?.trim() ?? '';

    if (email.isNotEmpty) {
      detalhes.add('E-mail: $email');
    }

    if (endereco.isNotEmpty) {
      detalhes.add('Endereço: $endereco');
    }

    if (detalhes.isEmpty) {
      return 'Sem informações adicionais.';
    }

    return detalhes.join(' • ');
  }

  /// Abre o formulário para cadastrar ou editar.
  Future<void> _abrirFormulario({Cliente? cliente}) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ClientFormPage(client: cliente),
      ),
    );

    if (!mounted) {
      return;
    }

    if (salvo == true) {
      // O ClienteController já atualiza sua lista
      // após a operação de cadastro ou edição.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cliente == null
                ? 'Cliente cadastrado com sucesso.'
                : 'Cliente atualizado com sucesso.',
          ),
        ),
      );
    }
  }

  /// Solicita confirmação antes de excluir um cliente.
  Future<void> _confirmarExclusao(Cliente cliente) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir cliente?'),
        content: Text(
          'Confirma a exclusão de ${cliente.nome}? '
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

    final id = cliente.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o cliente.',
          ),
        ),
      );
      return;
    }

    try {
      await context.read<ClienteController>().excluir(id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cliente excluído com sucesso.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir o cliente. '
            'Verifique se existem equipamentos ou '
            'ordens de serviço vinculados a ele.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa as alterações notificadas pelo controlador.
    final controlador = context.watch<ClienteController>();

    final clientesFiltrados = controlador.clientes
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
                title: 'Clientes',
                subtitle:
                    'Cadastre e consulte os responsáveis '
                    'pelos equipamentos atendidos.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      _abrirFormulario();
                    },
                    icon: const Icon(
                      Icons.person_add_alt_1_outlined,
                    ),
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
                    hintText:
                        'Nome, CPF/CNPJ, telefone ou e-mail',
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

              // Indica operações em andamento.
              if (controlador.carregando) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // Apresenta falhas de consulta ao banco.
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
                            _carregarClientes();
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

              Text(
                _textoBusca.trim().isEmpty
                    ? '${controlador.clientes.length} clientes cadastrados'
                    : '${clientesFiltrados.length} clientes encontrados',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),

              // Mensagem quando a pesquisa não encontra clientes.
              if (!controlador.carregando &&
                  controlador.erro == null &&
                  clientesFiltrados.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _textoBusca.trim().isEmpty
                            ? 'Nenhum cliente cadastrado. '
                              'Utilize "Novo cliente" '
                              'para iniciar o cadastro.'
                            : 'Nenhum cliente encontrado '
                              'para a pesquisa informada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // Lista os clientes reais provenientes do SQLite.
              ...clientesFiltrados.map(
                (cliente) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EntityListCard(
                    title: cliente.nome,
                    subtitle:
                        'Documento: ${cliente.documento} '
                        '• Telefone: ${cliente.telefone}',
                    details: _detalhesCliente(cliente),
                    leadingIcon: Icons.business_outlined,
                    onEdit: () {
                      _abrirFormulario(cliente: cliente);
                    },
                    onDelete: () {
                      _confirmarExclusao(cliente);
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
