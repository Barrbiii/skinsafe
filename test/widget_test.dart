// Это базовый тест виджетов Flutter.
//
// Чтобы взаимодействовать с виджетом в тесте, используйте WidgetTester.
// Например, вы можете отправлять жесты tap и scroll или использовать
// WidgetTester для поиска дочерних виджетов в дереве виджетов,
// чтения текста и проверки значений свойств виджетов.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skinsafe/main.dart';

void main() {
  testWidgets('Экран авторизации SkinSafe отображается корректно',
          (WidgetTester tester) async {
        // Собираем приложение и запускаем один кадр.
        await tester.pumpWidget(const SkinSafeApp());

        // Проверяем, что заголовок экрана авторизации отображается.
        expect(find.text('Регистрация SkinSafe'), findsOneWidget);

        // Проверяем, что поля ввода присутствуют.
        expect(find.text('Логин'), findsOneWidget);
        expect(find.text('Пароль'), findsOneWidget);
        expect(find.text('Подтвердите пароль'), findsOneWidget);

        // Проверяем наличие кнопки регистрации.
        expect(find.text('Зарегистрироваться'), findsOneWidget);
      });
}