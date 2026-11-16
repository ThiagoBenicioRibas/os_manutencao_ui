import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/item_utilizado.dart';
import 'package:os_manutencao_ui/repositories/item_utilizado_repository.dart';

/// Gerencia os itens e materiais utilizados nas ordens
/// de serviço e notifica a interface sobre alterações.
class ItemUtilizadoController extends ChangeNotifier {
  ItemUtilizadoController({ItemUtilizadoRepository? repositorio})
      : _repositorio = repositorio ?? ItemUtilizadoRepository();

  final ItemUtilizadoRepository _repositorio;

  List<ItemUtilizado> _itens = [];
  bool _carregando = false;
  String? _erro;
  int? _ordemIdFiltro;
  int _consulta = 0;
  bool _dadosCarregados = false;

  bool get dadosDisponiveis =>
      _dadosCarregados && !_carregando && _erro == null;

  /// Lista de itens disponível para a interface.
  List<ItemUtilizado> get itens => List<ItemUtilizado>.unmodifiable(_itens);

  /// Indica se existe uma operação em andamento.
  bool get carregando => _carregando;

  /// Mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Identifica a ordem de serviço utilizada no filtro.
  int? get ordemIdFiltro => _ordemIdFiltro;

  /// Soma os subtotais dos itens atualmente carregados.
  ///
  /// O resultado é expresso em centavos.
  int get totalCentavos {
    return _itens.fold<int>(
      0,
      (total, item) => total + item.subtotalCentavos,
    );
  }

  /// Carrega todos os itens cadastrados.
  Future<void> carregar() async {
    _ordemIdFiltro = null;
    await _carregarLista();
  }

  /// Carrega somente os itens de determinada OS.
  Future<void> carregarPorOrdem(int ordemId) async {
    _ordemIdFiltro = ordemId;
    await _carregarLista();
  }

  /// Consulta os itens de acordo com o filtro atual.
  Future<List<ItemUtilizado>> _consultarItens() {
    final ordemId = _ordemIdFiltro;

    if (ordemId == null) {
      return _repositorio.listar();
    }

    return _repositorio.listarPorOrdem(ordemId);
  }

  /// Recarrega a lista e notifica a interface.
  Future<void> _carregarLista() async {
    final consulta = ++_consulta;
    _carregando = true;
    _erro = null;
    _dadosCarregados = false;
    _itens = [];
    notifyListeners();

    try {
      final itens = await _consultarItens();
      if (consulta != _consulta) return;
      _itens = itens;
      _dadosCarregados = true;
    } catch (_) {
      if (consulta != _consulta) return;
      _erro = 'Não foi possível carregar os materiais. Tente novamente.';
      rethrow;
    } finally {
      if (consulta == _consulta) {
        _carregando = false;
        notifyListeners();
      }
    }
  }

  /// Cadastra um item e atualiza a lista.
  Future<int> cadastrar(ItemUtilizado item) {
    return _executarAlteracao(
      () => _repositorio.inserir(item),
    );
  }

  /// Atualiza um item existente e recarrega a lista.
  Future<int> atualizar(ItemUtilizado item) {
    return _executarAlteracao(
      () => _repositorio.atualizar(item),
    );
  }

  /// Exclui um item pelo identificador.
  Future<int> excluir(int id) {
    return _executarAlteracao(
      () => _repositorio.excluir(id),
    );
  }

  /// Consulta o valor total dos materiais de uma OS
  /// diretamente no repositório.
  Future<int> calcularTotalPorOrdemCentavos(int ordemId) {
    return _repositorio.calcularTotalCentavos(ordemId);
  }

  /// Executa uma alteração e sincroniza a lista,
  /// preservando o filtro selecionado.
  Future<int> _executarAlteracao(
    Future<int> Function() operacao,
  ) async {
    _carregando = true;
    _erro = null;
    _dadosCarregados = false;
    _itens = [];
    ++_consulta;
    notifyListeners();

    try {
      final resultado = await operacao();

      try {
        await _carregarLista();
      } catch (_) {
        _erro =
            'Alteração salva, mas não foi possível atualizar os materiais. Recarregue a lista.';
      }

      return resultado;
    } catch (_) {
      _erro =
          'Não foi possível salvar a alteração dos materiais. Confira os dados e tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
