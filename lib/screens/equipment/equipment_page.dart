
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:os_manutencao_ui/controllers/cliente_controller.dart';
import 'package:os_manutencao_ui/controllers/equipamento_controller.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/screens/equipment/equipment_form_page.dart';
import 'package:os_manutencao_ui/widgets/app_page_header.dart';
import 'package:os_manutencao_ui/widgets/entity_list_card.dart';
import 'package:os_manutencao_ui/widgets/section_card.dart';

/// Listagem de equipamentos conectada ao SQLite.
///
/// Preserva a estrutura visual original do professor
/// e utiliza os controladores para consultar os dados.
class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  String _textoBusca = '';

  @override
  void initState() {
    super.initState();

    // Carrega os dados após a construção inicial da tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _carregarDados();
      }
    });
  }

  /// Consulta os clientes e equipamentos cadastrados.
  Future<void> _carregarDados() async {
    final clienteController = context.read<ClienteController>();
    final equipamentoController =
        context.read<EquipamentoController>();

    try {
      await clienteController.carregar();
    } catch (_) {
      // O controlador registra o erro para a interface.
    }

    try {
      await equipamentoController.carregar();
    } catch (_) {
      // O controlador registra o erro para a interface.
    }
  }

  /// Verifica se um equipamento corresponde à pesquisa.
  bool _correspondeBusca(
    Equipamento equipamento,
    Map<int, String> nomesClientes,
  ) {
    final busca = _textoBusca.trim().toLowerCase();

    if (busca.isEmpty) {
      return true;
    }

    final nomeCliente =
        nomesClientes[equipamento.clienteId] ?? '';

    final campos = [
      equipamento.tipo,
      equipamento.marca ?? '',
      equipamento.modelo ?? '',
      equipamento.numeroSerie ?? '',
      equipamento.patrimonio ?? '',
      nomeCliente,
    ];

    return campos.any(
      (campo) => campo.toLowerCase().contains(busca),
    );
  }

  /// Mostra as informações complementares do equipamento.
  String _detalhesEquipamento(Equipamento equipamento) {
    final detalhes = <String>[];

    final modelo = equipamento.modelo?.trim() ?? '';
    final serie = equipamento.numeroSerie?.trim() ?? '';
    final patrimonio = equipamento.patrimonio?.trim() ?? '';
    final observacoes = equipamento.observacoes?.trim() ?? '';

    if (modelo.isNotEmpty) {
      detalhes.add('Modelo: $modelo');
    }

    if (serie.isNotEmpty) {
      detalhes.add('Série: $serie');
    }

    if (patrimonio.isNotEmpty) {
      detalhes.add('Patrimônio: $patrimonio');
    }

    if (observacoes.isNotEmpty) {
      detalhes.add('Observações: $observacoes');
    }

    if (detalhes.isEmpty) {
      return 'Sem informações adicionais.';
    }

    return detalhes.join(' • ');
  }

  /// Abre o formulário para cadastrar ou editar.
  Future<void> _abrirFormulario({
    Equipamento? equipamento,
  }) async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EquipmentFormPage(
          equipment: equipamento,
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
            equipamento == null
                ? 'Equipamento cadastrado com sucesso.'
                : 'Equipamento atualizado com sucesso.',
          ),
        ),
      );
    }
  }

  /// Solicita confirmação antes de excluir o equipamento.
  Future<void> _confirmarExclusao(
    Equipamento equipamento,
  ) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Excluir equipamento?'),
        content: Text(
          'Confirma a exclusão do equipamento '
          '${equipamento.tipo}? '
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

    final id = equipamento.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível identificar o equipamento.',
          ),
        ),
      );
      return;
    }

    try {
      await context.read<EquipamentoController>().excluir(id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Equipamento excluído com sucesso.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível excluir o equipamento. '
            'Verifique se existem ordens de serviço '
            'vinculadas a ele.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa as alterações dos controladores.
    final equipamentoController =
        context.watch<EquipamentoController>();

    final clienteController =
        context.watch<ClienteController>();

    // Relaciona os identificadores aos nomes dos clientes.
    final nomesClientes = <int, String>{
      for (final cliente in clienteController.clientes)
        if (cliente.id != null) cliente.id!: cliente.nome,
    };

    final equipamentosFiltrados = equipamentoController
        .equipamentos
        .where(
          (equipamento) => _correspondeBusca(
            equipamento,
            nomesClientes,
          ),
        )
        .toList();

    final carregando = equipamentoController.carregando ||
        clienteController.carregando;

    final possuiErro = equipamentoController.erro != null ||
        clienteController.erro != null;

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
                subtitle:
                    'Ativos vinculados aos clientes e '
                    'utilizados nas ordens de serviço.',
                actions: [
                  FilledButton.icon(
                    onPressed: () {
                      _abrirFormulario();
                    },
                    icon: const Icon(
                      Icons.add_circle_outline,
                    ),
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
                    hintText:
                        'Tipo, marca, modelo, série, '
                        'patrimônio ou cliente',
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

              // Indica o carregamento dos dados.
              if (carregando) ...[
                const LinearProgressIndicator(),
                const SizedBox(height: 16),
              ],

              // Apresenta eventuais erros dos controladores.
              if (possuiErro) ...[
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
                        if (equipamentoController.erro != null)
                          Text(equipamentoController.erro!),
                        if (clienteController.erro != null)
                          Text(clienteController.erro!),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _carregarDados,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quantidade de equipamentos encontrados.
              Text(
                _textoBusca.trim().isEmpty
                    ? '${equipamentoController.equipamentos.length} '
                      'equipamentos cadastrados'
                    : '${equipamentosFiltrados.length} '
                      'equipamentos encontrados',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),

              const SizedBox(height: 12),

              // Informa quando não existem registros.
              if (!carregando &&
                  !possuiErro &&
                  equipamentosFiltrados.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        _textoBusca.trim().isEmpty
                            ? 'Nenhum equipamento cadastrado. '
                              'Utilize "Novo equipamento" '
                              'para iniciar o cadastro.'
                            : 'Nenhum equipamento encontrado '
                              'para a pesquisa informada.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

              // Lista os equipamentos reais do SQLite.
              ...equipamentosFiltrados.map(
                (equipamento) {
                  final nomeCliente =
                      nomesClientes[equipamento.clienteId] ??
                          'Cliente não encontrado';

                  final marca =
                      equipamento.marca?.trim().isNotEmpty == true
                          ? equipamento.marca!
                          : 'Não informada';

                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: EntityListCard(
                      title: equipamento.tipo,
                      subtitle:
                          'Cliente: $nomeCliente • Marca: $marca',
                      details:
                          _detalhesEquipamento(equipamento),
                      leadingIcon:
                          Icons.precision_manufacturing_outlined,
                      onEdit: () {
                        _abrirFormulario(
                          equipamento: equipamento,
                        );
                      },
                      onDelete: () {
                        _confirmarExclusao(equipamento);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
