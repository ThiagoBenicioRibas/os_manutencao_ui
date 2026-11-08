
import 'package:flutter_test/flutter_test.dart';
import 'package:os_manutencao_ui/main.dart';

void main() {
  testWidgets('Exibe a tela inicial de acesso', (tester) async {
    await tester.pumpWidget(const OrdemServicoUiApp());

    expect(
      find.text('Sistema de Ordem de Serviço'),
      findsOneWidget,
    );

    expect(
      find.text('Entrar'),
      findsOneWidget,
    );
  });
}
