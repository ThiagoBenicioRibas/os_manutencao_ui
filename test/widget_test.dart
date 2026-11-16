import 'package:flutter/material.dart';

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

  testWidgets('nome obrigatório impede acesso e mantém foco no campo',
      (tester) async {
    await tester.pumpWidget(const OrdemServicoUiApp());
    await tester.enterText(find.byType(TextFormField), '   ');
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe seu nome para entrar.'), findsOneWidget);
    expect(find.text('Dashboard'), findsNothing);
    expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue);
    expect(find.text('Senha'), findsNothing);
    expect(find.text('Visualizar interface sem autenticação'), findsNothing);
  });

  testWidgets('entrada por teclado, saída e nova entrada por botão',
      (tester) async {
    await tester.pumpWidget(const OrdemServicoUiApp());
    await tester.enterText(find.byType(TextFormField), '  Ana Maria  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Identificação: Ana Maria'), findsOneWidget);
    expect(find.text('Sistema de Ordem de Serviço'), findsNothing);
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
    expect(find.text('Sistema de Ordem de Serviço'), findsOneWidget);
    expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty);
    expect(find.text('Identificação: Ana Maria'), findsNothing);
    await tester.enterText(find.byType(TextFormField), 'João');
    await tester.tap(find.text('Entrar'));
    await tester.pump();
    expect(find.text('Identificação: João'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip('Sair'));
    await tester.pumpAndSettle();
  });
}
