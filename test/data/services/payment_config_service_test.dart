import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';

void main() {
  group('PaymentConfigService Telegram Links Tests', () {
    final service = PaymentConfigService.instance;

    setUp(() {
      // Reset keys
      service.deleteKey('telegram_support_link');
      service.deleteKey('telegram_channel_link');
    });

    tearDown(() {
      service.deleteKey('telegram_support_link');
      service.deleteKey('telegram_channel_link');
    });

    test('defaults to fallback links', () {
      expect(service.telegramSupportLinkValue, 'https://t.me/matericetbot');
      expect(service.telegramChannelLinkValue, 'https://t.me/MatricET');
      expect(service.telegramLinkValue, service.telegramSupportLinkValue);
      expect(ProfileActionsHelper.fallbackTelegramChannelLink, 'https://t.me/MatricET');
      expect(ProfileActionsHelper.fallbackTelegramSupportLink, 'https://t.me/matericetbot');
    });

    test('updates support link independently via telegram_support_link row', () {
      service.applyRow({
        'key': 'telegram_support_link',
        'value': 'https://t.me/matric_support_bot',
      });

      expect(service.telegramSupportLinkValue, 'https://t.me/matric_support_bot');
      expect(service.telegramLinkValue, 'https://t.me/matric_support_bot');
      // Channel link remains default
      expect(service.telegramChannelLinkValue, 'https://t.me/MatricET');
    });

    test('updates channel link independently via telegram_channel_link row', () {
      service.applyRow({
        'key': 'telegram_channel_link',
        'value': 'https://t.me/matric_community',
      });

      expect(service.telegramChannelLinkValue, 'https://t.me/matric_community');
      // Support link remains default
      expect(service.telegramSupportLinkValue, 'https://t.me/matericetbot');
    });

    test('supports telegram_community_link alias for channel', () {
      service.applyRow({
        'key': 'telegram_community_link',
        'value': 'https://t.me/matric_students',
      });

      expect(service.telegramChannelLinkValue, 'https://t.me/matric_students');
    });

    test('supports legacy telegram_link row for support', () {
      service.applyRow({
        'key': 'telegram_link',
        'value': 'https://t.me/legacy_support',
      });

      expect(service.telegramSupportLinkValue, 'https://t.me/legacy_support');
    });

    test('deleteKey resets individual links back to default', () {
      service.applyRow({
        'key': 'telegram_support_link',
        'value': 'https://t.me/matric_support_bot',
      });
      service.applyRow({
        'key': 'telegram_channel_link',
        'value': 'https://t.me/matric_community',
      });

      expect(service.telegramSupportLinkValue, 'https://t.me/matric_support_bot');
      expect(service.telegramChannelLinkValue, 'https://t.me/matric_community');

      // Delete support
      service.deleteKey('telegram_support_link');
      expect(service.telegramSupportLinkValue, 'https://t.me/matericetbot');
      expect(service.telegramChannelLinkValue, 'https://t.me/matric_community');

      // Delete channel
      service.deleteKey('telegram_channel_link');
      expect(service.telegramChannelLinkValue, 'https://t.me/MatricET');
    });
  });
}
