import 'package:flutter/foundation.dart';

class IdentificacaoController extends ChangeNotifier {
  static const limiteNome = 80;

  String? _nome;

  String? get nome => _nome;
  bool get identificado => _nome != null;

  static String? validarNome(String? valor) {
    final nome = valor?.trim() ?? '';
    if (nome.isEmpty) return 'Informe seu nome para entrar.';
    if (nome.length > limiteNome) {
      return 'Use até 80 caracteres para o nome.';
    }
    return null;
  }

  void entrar(String nome) {
    final erro = validarNome(nome);
    if (erro != null) throw ArgumentError(erro);
    _nome = nome.trim();
    notifyListeners();
  }

  void sair() {
    _nome = null;
    notifyListeners();
  }
}
