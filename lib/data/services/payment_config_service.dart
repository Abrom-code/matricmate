import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── PaymentConfig

/// A single payment method built from `app_config` rows.
class PaymentConfig {
  const PaymentConfig({
    required this.key,
    required this.label,
    required this.account,
    required this.holder,
    required this.icon,
    this.isFeatured = false,
  });

  /// Stable key used as `payment_method` value in `payment_receipts`.
  final String key;
  final String label;
  final String account;
  final String holder;
  final IconData icon;
  final bool isFeatured;

  @override
  bool operator ==(Object other) => other is PaymentConfig && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

// ── PaymentConfigService ──────────────────────────────────────────────────────

/// Single source of truth for payment config loaded from `app_config`.
class PaymentConfigService {
  PaymentConfigService._();
  static final instance = PaymentConfigService._();

  // Internal mutable state (built-ins keyed by DB key)──
  final _accounts = <String, String>{};
  final _holders = <String, String>{};

  // Built-in method definitions; only included when account is non-empty
  static const _builtIns = [
    _BuiltIn(
      key: 'payment_telebirr',
      holderKey: 'payment_telebirr_holder',
      label: 'Telebirr',
      subtitle: 'Fast mobile payment',
      icon: Icons.account_balance_wallet,
      isFeatured: true,
    ),
    _BuiltIn(
      key: 'payment_cbe_birr',
      holderKey: 'payment_cbe_birr_holder',
      label: 'CBE',
      subtitle: 'Direct from Commercial Bank',
      icon: Icons.account_balance,
    ),
    _BuiltIn(
      key: 'payment_abyssinia',
      holderKey: 'payment_abyssinia_holder',
      label: 'Abyssinia',
      subtitle: 'Direct from Abyssinia Bank',
      icon: Icons.account_balance,
    ),
    _BuiltIn(
      key: 'payment_mpesa',
      holderKey: 'payment_mpesa_holder',
      label: 'M-PESA',
      subtitle: 'M-Pesa Safaricom wallet',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  /// All currently active payment methods.
  final methods = <PaymentConfig>[].obs;

  /// Dynamic plan prices in ETB loaded from `app_config` (keyed by plan key e.g. '1_year').
  final planPrices = <String, int>{}.obs;

  /// Returns the price for a plan, using dynamic app_config price if present,
  /// falling back to the plan's defaultPrice.
  int getPriceForPlan(String planKey, int defaultPrice) {
    return planPrices[planKey] ?? defaultPrice;
  }

  /// Subscription price for the featured (1 year) plan in ETB (convenience).
  int get subscriptionPrice => planPrices['1_year'] ?? 250;

  /// Telegram support link (loaded from app_config, falls back to hardcoded).
  final telegramLink = 'https://t.me/matric_mate'.obs;

  /// Share / invite link (loaded from app_config, falls back to empty).
  final shareLink = ''.obs;

  /// Reactive loading and error state
  final isLoading = false.obs;
  final hasError = false.obs;
  final isLoaded = false.obs;

  // Load from Supabase (called at startup and when needed)
  Future<void> load({bool force = false}) async {
    if (isLoading.value && !force) return;

    isLoading.value = true;
    hasError.value = false;

    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value')
          .timeout(const Duration(seconds: 10));

      debugPrint('[PaymentConfig] loaded ${rows.length} rows from app_config');

      for (final row in rows) {
        debugPrint(
          '[PaymentConfig] row: key=${row['key']} value=${row['value']}',
        );
        _applyToState(row);
      }
      _rebuildMethods();
      debugPrint(
        '[PaymentConfig] methods built: ${methods.map((m) => m.label).toList()}',
      );
      isLoaded.value = true;
      hasError.value = false;
    } catch (e, st) {
      // Log failure for debugging
      debugPrint('[PaymentConfig] load() failed: $e\n$st');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  /// Called by RealtimeService when a row is deleted from `app_config`.
  void deleteKey(String key) {
    if (key.isEmpty) return;
    debugPrint('[PaymentConfig] deleteKey: $key');

    switch (key) {
      case 'payment_telebirr':
      case 'payment_cbe_birr':
      case 'payment_abyssinia':
      case 'payment_mpesa':
        _accounts.remove(key);

      case 'payment_telebirr_holder':
      case 'payment_cbe_birr_holder':
      case 'payment_abyssinia_holder':
      case 'payment_mpesa_holder':
        _holders.remove(key);

      case 'payment_extra_accounts':
        _accounts.remove('payment_extra_accounts');

      case 'telegram_link':
        telegramLink.value = 'https://t.me/matric_mate';

      case 'share_link':
        shareLink.value = '';

      case 'plan_price_6_months':
        planPrices.remove('6_months');
      case 'plan_price_1_year':
        planPrices.remove('1_year');
      case 'plan_price_2_years':
        planPrices.remove('2_years');
      case 'plan_price_3_years':
        planPrices.remove('3_years');
      case 'plan_price_4_years':
        planPrices.remove('4_years');
    }

    _rebuildMethods();
  }

  /// Called by [RealtimeService] for every INSERT/UPDATE on `app_config`.
  void applyRow(Map<String, dynamic> row) {
    debugPrint(
      '[PaymentConfig] applyRow: key=${row['key']} value=${row['value']}',
    );
    _applyToState(row);
    _rebuildMethods();
  }

  // Internal helpers

  void _applyToState(Map<String, dynamic> row) {
    final key = row['key']?.toString() ?? '';
    // Guard against literal "EMPTY" string from Supabase dashboard
    final raw = row['value']?.toString() ?? '';
    final value = (raw == 'EMPTY') ? '' : raw;

    switch (key) {
      // Account numbers
      case 'payment_telebirr':
      case 'payment_cbe_birr':
      case 'payment_abyssinia':
      case 'payment_mpesa':
        _accounts[key] = value;

      // Holder names
      case 'payment_telebirr_holder':
      case 'payment_cbe_birr_holder':
      case 'payment_abyssinia_holder':
      case 'payment_mpesa_holder':
        _holders[key] = value;

      // Extra / custom accounts (JSON array)
      case 'payment_extra_accounts':
        _accounts['payment_extra_accounts'] = value;

      // Plan prices
      case 'plan_price_6_months':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) planPrices['6_months'] = parsed;

      case 'plan_price_1_year':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) planPrices['1_year'] = parsed;

      case 'plan_price_2_years':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) planPrices['2_years'] = parsed;

      case 'plan_price_3_years':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) planPrices['3_years'] = parsed;

      case 'plan_price_4_years':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) planPrices['4_years'] = parsed;

      // Legacy subscription price fallback
      case 'subscription_price':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0 && !planPrices.containsKey('1_year')) {
          planPrices['1_year'] = parsed;
        }

      // Telegram support link
      case 'telegram_link':
        if (value.isNotEmpty) telegramLink.value = value;

      // Share / invite link
      case 'share_link':
        shareLink.value = value;
    }
  }

  /// Rebuilds [methods] from current state.
  void _rebuildMethods() {
    final result = <PaymentConfig>[];

    for (final b in _builtIns) {
      final account = _accounts[b.key] ?? '';
      if (account.isEmpty) continue; // hidden until admin sets the account
      result.add(
        PaymentConfig(
          key: b.key,
          label: b.label,
          account: account,
          holder: _holders[b.holderKey] ?? '',
          icon: b.icon,
          isFeatured: b.isFeatured,
        ),
      );
    }

    // Parse extra accounts JSON
    final extrasRaw = _accounts['payment_extra_accounts'] ?? '';
    final extras = _parseExtras(extrasRaw);
    result.addAll(extras);

    methods.value = result;
    debugPrint(
      '[PaymentConfig] _rebuildMethods: ${result.map((m) => '${m.label}(${m.account})').toList()}',
    );
  }

  List<PaymentConfig> _parseExtras(String raw) {
    if (raw.isEmpty || raw == '[]') return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .where(
            (e) =>
                e['account']?.toString().isNotEmpty == true &&
                e['key']?.toString().isNotEmpty == true,
          )
          .map(
            (e) => PaymentConfig(
              key: e['key']?.toString() ?? '',
              label: e['label']?.toString() ?? e['key']?.toString() ?? '',
              account: e['account']?.toString() ?? '',
              holder: e['holder']?.toString() ?? '',
              icon: Icons.account_balance_wallet_outlined,
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }
}

// Private helper

class _BuiltIn {
  const _BuiltIn({
    required this.key,
    required this.holderKey,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.isFeatured = false,
  });

  final String key;
  final String holderKey;
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isFeatured;
}
