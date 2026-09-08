import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avaliatech/main.dart';
import 'package:avaliatech/data/avaliation_store.dart';
import 'package:avaliatech/ui/common.dart';

void main() {
  late AvaliationStore store;
  setUp(() async {
    AppNav.selected.value = 0;
    SharedPreferences.setMockInitialValues({});
    store = AvaliationStore(await SharedPreferences.getInstance());
    await store.carregar();
  });
  tearDown(() {
    AppNav.selected.value = 0;
    store.dispose();
  });
  testWidgets('o professor entra e encontra as quatro abas de gestão', (
    tester,
  ) async {
    await tester.pumpWidget(AvaliaTechApp(store: store));
    expect(find.text('AvaliaTech'), findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Prof. Ana!'), findsOneWidget);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.map((e) => e.label).toList(), [
      'Início',
      'Turmas',
      'Avaliações',
      'Resultados',
    ]);
  });
  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets('perfil do estudante rola sem overflow em $size', (
      tester,
    ) async {
      await tester.pumpWidget(AvaliaTechApp(store: store));
      await tester.tap(find.text('Estudante'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.tap(find.text('Perfil'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Protótipo local • Dados de demonstração'),
        200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sair da conta').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.scrollUntilVisible(
        find.text('Dados pessoais'),
        -200,
        scrollable: find.byType(Scrollable),
      );
      await tester.pumpAndSettle();
      expect(find.text('Editar').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('o estudante possui perfil no lugar de resultados', (
    tester,
  ) async {
    await tester.pumpWidget(AvaliaTechApp(store: store));
    await tester.tap(find.text('Estudante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Lucas!'), findsOneWidget);
    final nav = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(nav.items.map((e) => e.label).toList(), [
      'Início',
      'Turmas',
      'Avaliações',
      'Perfil',
    ]);
  });
}
