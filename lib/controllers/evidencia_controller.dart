import 'package:flutter/foundation.dart';
import 'package:os_manutencao_ui/models/evidencia.dart';
import 'package:os_manutencao_ui/repositories/evidencia_repository.dart';

/// Gerencia as evidências fotográficas das ordens
/// de serviço e notifica a interface sobre alterações.
///
/// Os registros são armazenados no SQLite.
/// O armazenamento dos arquivos físicos das imagens
/// será realizado por um serviço separado.
class EvidenciaController extends ChangeNotifier {
  EvidenciaController({EvidenciaRepository? repositorio})
      : _repositorio = repositorio ?? EvidenciaRepository();

  final EvidenciaRepository _repositorio;

  List<Evidencia> _evidencias = [];
  bool _carregando = false;
  String? _erro;
  int? _ordemIdFiltro;

  /// Evidências disponíveis para a interface.
  List<Evidencia> get evidencias => List<Evidencia>.unmodifiable(_evidencias);

  /// Indica se uma operação está em andamento.
  bool get carregando => _carregando;

  /// Mensagem da última falha, quando houver.
  String? get erro => _erro;

  /// Ordem de serviço utilizada no filtro atual.
  int? get ordemIdFiltro => _ordemIdFiltro;

  /// Quantidade de evidências atualmente carregadas.
  int get quantidade => _evidencias.length;

  /// Carrega todas as evidências cadastradas.
  Future<void> carregar() async {
    _ordemIdFiltro = null;
    await _carregarLista();
  }

  /// Carrega somente as evidências de determinada OS.
  Future<void> carregarPorOrdem(int ordemId) async {
    _ordemIdFiltro = ordemId;
    await _carregarLista();
  }

  /// Consulta as evidências conforme o filtro atual.
  Future<List<Evidencia>> _consultarEvidencias() {
    final ordemId = _ordemIdFiltro;

    if (ordemId == null) {
      return _repositorio.listar();
    }

    return _repositorio.listarPorOrdem(ordemId);
  }

  /// Atualiza a lista e notifica a interface.
  Future<void> _carregarLista() async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      _evidencias = await _consultarEvidencias();
    } catch (_) {
      _erro = 'Não foi possível carregar as evidências. Tente novamente.';
      rethrow;
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Cadastra uma evidência no SQLite.
  ///
  /// Retorna o identificador gerado.
  Future<int> cadastrar(Evidencia evidencia) {
    return _executarAlteracao(
      () => _repositorio.inserir(evidencia),
    );
  }

  /// Atualiza uma evidência existente.
  ///
  /// Retorna a quantidade de registros atualizados.
  Future<int> atualizar(Evidencia evidencia) {
    return _executarAlteracao(
      () => _repositorio.atualizar(evidencia),
    );
  }

  /// Exclui o registro de uma evidência pelo ID.
  ///
  /// A remoção do arquivo físico da fotografia
  /// será coordenada pelo serviço de armazenamento.
  Future<int> excluir(int id) {
    return _executarAlteracao(
      () => _repositorio.excluir(id),
    );
  }

  /// Executa uma alteração e sincroniza a lista,
  /// preservando o filtro selecionado.
  Future<int> _executarAlteracao(
    Future<int> Function() operacao,
  ) async {
    _carregando = true;
    _erro = null;
    notifyListeners();

    try {
      final resultado = await operacao();

      _evidencias = await _consultarEvidencias();

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
