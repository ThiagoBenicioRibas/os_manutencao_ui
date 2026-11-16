import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/cliente.dart';
import 'package:os_manutencao_ui/repositories/cliente_repository.dart';

/// Gerencia os dados de clientes e notifica a interface
/// quando ocorrem alterações.
class ClienteController extends ChangeNotifier {
  ClienteController({ClienteRepository? repositorio})
      : _repositorio = repositorio ?? ClienteRepository();

  final ClienteRepository _repositorio;

  List<Cliente> _clientes = [];
  bool _carregando = false;
  String? _erro;

  /// Lista de clientes disponível para a interface.
  List<Cliente> get clientes => List<Cliente>.unmodifiable(_clientes);

  /// Informa se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Armazena a mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Carrega os clientes cadastrados no SQLite.
  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _clientes = await _repositorio.listar();
    } catch (_) {
      _erro = 'Não foi possível carregar os clientes. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cadastra um cliente e atualiza a lista.
  ///
  /// Retorna o identificador gerado pelo banco.
  Future<int> cadastrar(Cliente cliente) {
    return _executarAlteracao(
      () => _repositorio.inserir(cliente),
    );
  }

  /// Atualiza um cliente e recarrega a lista.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Cliente cliente) {
    return _executarAlteracao(
      () => _repositorio.atualizar(cliente),
    );
  }

  /// Exclui um cliente e atualiza a lista.
  ///
  /// O SQLite protege clientes que possuem registros
  /// vinculados por chaves estrangeiras.
  Future<int> excluir(int id) {
    return _executarAlteracao(
      () => _repositorio.excluir(id),
    );
  }

  /// Executa uma alteração e sincroniza os dados
  /// disponibilizados para a interface.
  Future<int> _executarAlteracao(
    Future<int> Function() operacao,
  ) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await operacao();

      _clientes = await _repositorio.listar();

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
