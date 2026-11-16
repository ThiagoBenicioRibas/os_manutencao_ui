import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/equipamento.dart';
import 'package:os_manutencao_ui/repositories/equipamento_repository.dart';

/// Gerencia os equipamentos e informa a interface
/// quando ocorrem alterações nos dados.
class EquipamentoController extends ChangeNotifier {
  EquipamentoController({EquipamentoRepository? repositorio})
      : _repositorio = repositorio ?? EquipamentoRepository();

  final EquipamentoRepository _repositorio;

  List<Equipamento> _equipamentos = [];
  bool _carregando = false;
  String? _erro;
  int? _clienteIdFiltro;

  /// Lista de equipamentos disponível para a interface.
  List<Equipamento> get equipamentos =>
      List<Equipamento>.unmodifiable(_equipamentos);

  /// Informa se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Armazena a mensagem da última falha.
  String? get erro => _erro;

  /// Identifica o cliente utilizado no filtro atual.
  int? get clienteIdFiltro => _clienteIdFiltro;

  /// Carrega todos os equipamentos cadastrados.
  Future<void> carregar() async {
    _clienteIdFiltro = null;
    await _carregarLista();
  }

  /// Carrega somente os equipamentos de um cliente.
  Future<void> carregarPorCliente(int clienteId) async {
    _clienteIdFiltro = clienteId;
    await _carregarLista();
  }

  /// Consulta os equipamentos conforme o filtro atual.
  Future<void> _carregarLista() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _equipamentos = await _consultarEquipamentos();
    } catch (_) {
      _erro = 'Não foi possível carregar os equipamentos. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Escolhe entre consultar todos os equipamentos
  /// ou somente os pertencentes ao cliente selecionado.
  Future<List<Equipamento>> _consultarEquipamentos() {
    final clienteId = _clienteIdFiltro;

    if (clienteId == null) {
      return _repositorio.listar();
    }

    return _repositorio.listarPorCliente(clienteId);
  }

  /// Cadastra um equipamento e atualiza a lista.
  Future<int> cadastrar(Equipamento equipamento) {
    return _executarAlteracao(
      () => _repositorio.inserir(equipamento),
    );
  }

  /// Atualiza um equipamento e recarrega a lista.
  Future<int> atualizar(Equipamento equipamento) {
    return _executarAlteracao(
      () => _repositorio.atualizar(equipamento),
    );
  }

  /// Exclui um equipamento pelo identificador.
  ///
  /// O SQLite impedirá a exclusão se houver ordens
  /// de serviço vinculadas ao equipamento.
  Future<int> excluir(int id) {
    return _executarAlteracao(
      () => _repositorio.excluir(id),
    );
  }

  /// Executa uma alteração e sincroniza a lista
  /// conforme o filtro que estiver selecionado.
  Future<int> _executarAlteracao(
    Future<int> Function() operacao,
  ) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await operacao();

      _equipamentos = await _consultarEquipamentos();

      return resultado;
    } catch (_) {
      _erro = 'Não foi possível concluir a operação. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }
}
