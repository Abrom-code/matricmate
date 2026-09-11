import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/data/services/session_service.dart';

void main() {
  group('Tester Whitelist Tests', () {
    test('yeabrom@gmail.com is correctly identified as whitelisted tester', () {
      expect(SessionService.isWhitelistedTester('yeabrom@gmail.com'), isTrue);
      expect(SessionService.isWhitelistedTester('YEABROM@GMAIL.COM'), isTrue);
      expect(SessionService.isWhitelistedTester(' yeabrom@gmail.com '), isTrue);
      expect(SessionService.isWhitelistedTester('Yeabrom@Gmail.Com'), isTrue);
    });

    test('regular user emails are not whitelisted', () {
      expect(SessionService.isWhitelistedTester('user@example.com'), isFalse);
      expect(SessionService.isWhitelistedTester('student@matricmate.com'), isFalse);
      expect(SessionService.isWhitelistedTester(null), isFalse);
      expect(SessionService.isWhitelistedTester(''), isFalse);
      expect(SessionService.isWhitelistedTester('   '), isFalse);
    });
  });
}
