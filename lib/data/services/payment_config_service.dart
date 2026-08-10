import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ── PaymentConfig

/// A single payment method built entirely from `app_config` rows.
/// Replaces the old hardcoded [PaymentMethod] enum for display purposes.
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

/// Single source of truth for all payment config loaded from `app_config`.
///
/// • [methods]           — reactive list of every visible payment method
///                         (built-ins that have a non-empty account + extras).
///                         The UI only reads this one list — no enum, no split.
/// • [subscriptionPrice] — reactive price in ETB.
///
/// Call [load()] once at startup. Realtime pushes call [applyRow()] per row.
class PaymentConfigService {
  PaymentConfigService._();
  static final instance = PaymentConfigService._();

  // ── Internal mutable state (built-ins keyed by DB key) ───────────────
  final _accounts = <String, String>{};
  final _holders = <String, String>{};

  // Built-in method definitions — order, label, icon, featured flag.
  // A built-in is only included in [methods] when its account is non-empty.
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

  // ── Public reactive state ─────────────────────────────────────────────
  /// All currently active payment methods — rebuilt whenever any row changes.
  final methods = <PaymentConfig>[].obs;

  /// Subscription price in ETB.
  final subscriptionPrice = 300.obs;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  // ── Load from Supabase (called once at startup) ───────────────────────
  Future<void> load() async {
    try {
      final rows = await Supabase.instance.client
          .from('app_config')
          .select('key, value');

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
      _loaded = true;
    } catch (e, st) {
      // Log so the developer can see what went wrong.
      debugPrint('[PaymentConfig] load() failed: $e\n$st');
    }
  }

  /// Called by [RealtimeService] when a row is deleted from `app_config`.
  /// Clears the cached value for that key and rebuilds [methods].
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

  // ── Internal helpers ──────────────────────────────────────────────────

  void _applyToState(Map<String, dynamic> row) {
    final key = row['key']?.toString() ?? '';
    // Guard against literal "EMPTY" string — Supabase dashboard shows
    // empty strings as "EMPTY" visually, but the actual value is ''.
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

      // Subscription price
      case 'subscription_price':
        final parsed = int.tryParse(value);
        if (parsed != null && parsed > 0) subscriptionPrice.value = parsed;
    }
  }

  /// Rebuilds [methods] from current state.
  /// A built-in is included only if its account number is non-empty.
  /// Extras from JSON are appended after built-ins.
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

// ── Private helper ────────────────────────────────────────────────────────────

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
