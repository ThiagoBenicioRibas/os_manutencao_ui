import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/controllers/identificacao_controller.dart';

void main() {
  test('exige nome e limita tamanho sem iniciar sessão inválida', () {
    final controller = IdentificacaoController();
    addTearDown(controller.dispose);
    expect(controller.identificado, isFalse);
    for (final nome in ['', '   ', 'a' * 81]) {
      expect(() => controller.entrar(nome), throwsArgumentError);
      expect(controller.nome, isNull);
    }
    expect(IdentificacaoController.validarNome(null), isNotNull);
  });

  test(
      'normaliza bordas, notifica entrada e saída e permite nova identificação',
      () {
    final controller = IdentificacaoController();
    addTearDown(controller.dispose);
    var notificacoes = 0;
    controller.addListener(() => notificacoes++);
    controller.entrar('  Ana Maria  ');
    expect(controller.nome, 'Ana Maria');
    expect(controller.identificado, isTrue);
    controller.sair();
    expect(controller.nome, isNull);
    expect(controller.identificado, isFalse);
    controller.entrar('João');
    expect(controller.nome, 'João');
    expect(notificacoes, 3);
  });

  test('aceita limite e uma nova instância começa sem identificação', () {
    final controller = IdentificacaoController();
    final novaSessao = IdentificacaoController();
    addTearDown(controller.dispose);
    addTearDown(novaSessao.dispose);
    controller.entrar('a' * 80);
    expect(controller.nome, hasLength(80));
    expect(novaSessao.identificado, isFalse);
  });
}
