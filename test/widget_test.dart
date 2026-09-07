import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:avaliatech/main.dart';
import 'package:avaliatech/data/avaliation_store.dart';

void main(){
  late AvaliationStore store;
  setUp(()async{SharedPreferences.setMockInitialValues({});store=AvaliationStore(await SharedPreferences.getInstance());await store.carregar();});
  tearDown((){store.dispose();});
  testWidgets('o professor entra e encontra as quatro abas de gestão',(tester)async{
    await tester.pumpWidget(AvaliaTechApp(store:store));
    expect(find.text('AvaliaTech'),findsOneWidget);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Prof. Ana!'),findsOneWidget);
    final nav=tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.items.map((e)=>e.label).toList(),['Início','Turmas','Avaliações','Resultados']);
  });
  testWidgets('o estudante possui perfil no lugar de resultados',(tester)async{
    await tester.pumpWidget(AvaliaTechApp(store:store));
    await tester.tap(find.text('Estudante'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Olá, Lucas!'),findsOneWidget);
    final nav=tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.items.map((e)=>e.label).toList(),['Início','Turmas','Avaliações','Perfil']);
  });
}
