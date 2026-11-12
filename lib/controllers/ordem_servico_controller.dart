
import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/ordem_servico.dart';
import 'package:os_manutencao_ui/repositories/ordem_servico_repository.dart';

/// Gerencia as ordens de serviço e notifica a interface
/// quando ocorrem alterações nos dados.
class OrdemServicoController extends ChangeNotifier {
  OrdemServicoController({OrdemServicoRepository? repositorio})
      : _repositorio = repositorio ?? OrdemServicoRepository();

  final OrdemServicoRepository _repositorio;

  List<OrdemServico> _ordens = [];
  bool _carregando = false;
  String? _erro;

  int? _clienteIdFiltro;
  int? _tecnicoIdFiltro;

  /// Lista de ordens disponível para a interface.
  List<OrdemServico> get ordens =>
      List<OrdemServico>.unmodifiable(_ordens);

  /// Indica se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Cliente utilizado no filtro atual.
  int? get clienteIdFiltro => _clienteIdFiltro;

  /// Técnico utilizado no filtro atual.
  int? get tecnicoIdFiltro => _tecnicoIdFiltro;

  /// Carrega todas as ordens de serviço.
  Future<void> carregar() async {
    _clienteIdFiltro = null;
    _tecnicoIdFiltro = null;

    await _carregarLista();
  }

  /// Carrega somente as ordens de determinado cliente.
  Future<void> carregarPorCliente(int clienteId) async {
    _clienteIdFiltro = clienteId;
    _tecnicoIdFiltro = null;

    await _carregarLista();
  }

  /// Carrega somente as ordens de determinado técnico.
  Future<void> carregarPorTecnico(int tecnicoId) async {
    _clienteIdFiltro = null;
    _tecnicoIdFiltro = tecnicoId;

    await _carregarLista();
  }

  /// Consulta as ordens conforme o filtro selecionado.
  Future<List<OrdemServico>> _consultarOrdens() {
    final clienteId = _clienteIdFiltro;
    final tecnicoId = _tecnicoIdFiltro;

    if (clienteId != null) {
      return _repositorio.listarPorCliente(clienteId);
    }

    if (tecnicoId != null) {
      return _repositorio.listarPorTecnico(tecnicoId);
    }

    return _repositorio.listar();
  }

  /// Carrega os dados e notifica a interface.
  Future<void> _carregarLista() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _ordens = await _consultarOrdens();
    } catch (e) {
      _erro = 'Não foi possível carregar as ordens de serviço: $e';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cadastra uma ordem de serviço.
  ///
  /// Retorna o identificador gerado pelo SQLite.
  Future<int> cadastrar(OrdemServico ordem) {
    return _executarAlteracao(
      () => _repositorio.inserir(ordem),
    );
  }

  /// Atualiza uma ordem de serviço existente.
  ///
  /// Retorna a quantidade de registros atualizados.
  ///
  /// Para alterar o status e registrar seu histórico,
  /// utilize o método alterarStatus.
  Future<int> atualizar(OrdemServico ordem) {
    return _executarAlteracao(
      () => _repositorio.atualizar(ordem),
    );
  }

  /// Altera o status de uma ordem de serviço.
  ///
  /// A alteração do status e o registro do histórico
  /// são realizados pelo repositório em uma única
  /// transação SQLite.
  ///
  /// Após a operação, a lista de ordens é atualizada
  /// e os filtros existentes são preservados.
  Future<void> alterarStatus({
    required int ordemId,
    required String novoStatus,
    String? observacao,
  }) async {
    await _executarAlteracao(() async {
      await _repositorio.alterarStatus(
        ordemId: ordemId,
        novoStatus: novoStatus,
        observacao: observacao,
      );

      // O método auxiliar utiliza int porque os métodos
      // anteriores retornam identificadores ou contagens.
      // O resultado não é utilizado nesta operação.
      return 1;
    });
  }

  /// Exclui uma ordem de serviço pelo identificador.
  ///
  /// Os registros dependentes configurados com
  /// ON DELETE CASCADE serão tratados pelo SQLite.
  Future<int> excluir(int id) {
    return _executarAlteracao(
      () => _repositorio.excluir(id),
    );
  }

  /// Executa uma alteração e atualiza a lista de ordens,
  /// preservando o filtro selecionado.
  Future<int> _executarAlteracao(
    Future<int> Function() operacao,
  ) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await operacao();

      _ordens = await _consultarOrdens();

      return resultado;
    } catch (e) {
      _erro = 'Não foi possível concluir a operação: $e';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
