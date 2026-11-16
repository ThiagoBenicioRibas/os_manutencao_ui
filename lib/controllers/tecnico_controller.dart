import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/tecnico.dart';
import 'package:os_manutencao_ui/repositories/tecnico_repository.dart';

/// Gerencia os dados dos técnicos e notifica a interface
/// quando ocorrem alterações.
class TecnicoController extends ChangeNotifier {
  TecnicoController({TecnicoRepository? repositorio})
      : _repositorio = repositorio ?? TecnicoRepository();

  final TecnicoRepository _repositorio;

  List<Tecnico> _tecnicos = [];
  bool _carregando = false;
  String? _erro;

  /// Lista de técnicos disponível para a interface.
  List<Tecnico> get tecnicos => List<Tecnico>.unmodifiable(_tecnicos);

  /// Informa se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Armazena a mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Carrega os técnicos cadastrados no SQLite.
  Future<void> carregar() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _tecnicos = await _repositorio.listar();
    } catch (_) {
      _erro = 'Não foi possível carregar os técnicos. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cadastra um técnico e atualiza a lista.
  ///
  /// Retorna o identificador gerado pelo banco.
  Future<int> cadastrar(Tecnico tecnico) {
    return _executarAlteracao(
      () => _repositorio.inserir(tecnico),
    );
  }

  /// Atualiza um técnico cadastrado e recarrega a lista.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Tecnico tecnico) {
    return _executarAlteracao(
      () => _repositorio.atualizar(tecnico),
    );
  }

  /// Exclui um técnico e atualiza a lista.
  ///
  /// O SQLite impedirá a exclusão quando existirem
  /// ordens de serviço vinculadas ao técnico.
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

      _tecnicos = await _repositorio.listar();

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
