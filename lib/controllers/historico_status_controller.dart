import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/historico_status.dart';
import 'package:os_manutencao_ui/repositories/historico_status_repository.dart';

/// Gerencia a consulta e o registro do histórico de status
/// das ordens de serviço.
class HistoricoStatusController extends ChangeNotifier {
  HistoricoStatusController({HistoricoStatusRepository? repositorio})
      : _repositorio = repositorio ?? HistoricoStatusRepository();

  final HistoricoStatusRepository _repositorio;

  List<HistoricoStatus> _historicos = [];
  bool _carregando = false;
  String? _erro;
  int? _ordemIdFiltro;

  /// Registros disponíveis para a interface.
  List<HistoricoStatus> get historicos =>
      List<HistoricoStatus>.unmodifiable(_historicos);

  /// Indica se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Ordem de serviço selecionada para filtragem.
  int? get ordemIdFiltro => _ordemIdFiltro;

  /// Carrega todos os registros de histórico.
  Future<void> carregar() async {
    _ordemIdFiltro = null;
    await _carregarLista();
  }

  /// Carrega o histórico de uma ordem específica.
  Future<void> carregarPorOrdem(int ordemId) async {
    _ordemIdFiltro = ordemId;
    await _carregarLista();
  }

  /// Consulta o repositório conforme o filtro atual.
  Future<List<HistoricoStatus>> _consultarHistoricos() {
    final ordemId = _ordemIdFiltro;

    if (ordemId == null) {
      return _repositorio.listar();
    }

    return _repositorio.listarPorOrdem(ordemId);
  }

  /// Atualiza a lista e comunica as alterações.
  Future<void> _carregarLista() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _historicos = await _consultarHistoricos();
    } catch (_) {
      _erro =
          'Não foi possível carregar o histórico de status. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Registra um novo evento no histórico.
  ///
  /// O histórico é tratado como registro de auditoria:
  /// não há métodos para editar ou excluir eventos.
  ///
  /// Na Etapa 6, o registro será integrado às regras
  /// de alteração de status das ordens de serviço.
  Future<int> registrar(HistoricoStatus historico) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final id = await _repositorio.inserir(historico);

      // Preserva o filtro que estiver selecionado.
      _historicos = await _consultarHistoricos();

      return id;
    } catch (_) {
      _erro = 'Não foi possível registrar o histórico. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
