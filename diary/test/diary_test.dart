import 'package:flutter_test/flutter_test.dart';
import 'package:diary/main.dart';

void main() {
  group('Тестирование моделей данных My Diary', () {
    test('Конвертация BlockContent в JSON и обратно', () {
      final block = BlockContent(type: 'text', value: 'Привет, дневник!');

      final json = block.toJson();
      expect(json['type'], 'text');
      expect(json['value'], 'Привет, дневник!');

      final restoredBlock = BlockContent.fromJson(json);
      expect(restoredBlock.type, 'text');
      expect(restoredBlock.value, 'Привет, дневник!');
    });

    test('Создание записи DiaryEntry и проверка начальных значений', () {
      final now = DateTime.now();
      final entry = DiaryEntry(
        id: 'test_id_123',
        title: 'Мой заголовок',
        blocks: [BlockContent(type: 'text', value: 'Текст')],
        date: now,
        moodEmoji: '🥳',
      );

      expect(entry.id, 'test_id_123');
      expect(entry.title, 'Мой заголовок');
      expect(entry.moodEmoji, '🥳');
      expect(entry.stickers, isEmpty);
    });
  });
}
