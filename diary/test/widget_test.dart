import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:diary/main.dart';

void main() {
  testWidgets('Проверка отображения главного экрана', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const DiaryApp());
    await tester.pumpAndSettle();
    expect(find.text('Мой Дневник'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
