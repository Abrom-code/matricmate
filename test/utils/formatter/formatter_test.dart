import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/formatter/formatter.dart';

void main() {
  group('AppFormatter', () {
    test('formats dates from epoch milliseconds', () {
      expect(AppFormatter.formatDate(0), 'Jan 1, 1970');
    });

    test('formats zero-padded durations', () {
      expect(AppFormatter.formattedTime(0), '00:00:00');
      expect(AppFormatter.formattedTime(3661), '01:01:01');
      expect(AppFormatter.formattedTime(59), '00:00:59');
    });
  });
}
