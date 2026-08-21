/// A selectable subscription plan displayed on the Premium screen.
///
/// Hardcoded defaults are overridden at runtime by dynamic prices loaded
/// from `app_config` via [PaymentConfigService.planPrices].
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.key,
    required this.title,
    required this.durationMonths,
    required this.defaultPrice,
    this.subtitle = '',
    this.isFeatured = false,
    this.badgeText,
  });

  /// Stable key stored in `payment_receipts.plan_key` and `users.subscription_plan`.
  final String key;

  /// UI display name (e.g. "1 Year").
  final String title;

  /// Number of months this plan grants.
  final int durationMonths;

  /// Fallback price when `app_config` hasn't loaded yet.
  final int defaultPrice;

  /// Short copy below the title on the plan card.
  final String subtitle;

  /// Whether this is the recommended plan (highlighted in UI).
  final bool isFeatured;

  /// Optional badge text (e.g. "⭐ Best Value", "SAVE 15%").
  final String? badgeText;

  /// All available plans in display order.
  static const List<SubscriptionPlan> all = [
    SubscriptionPlan(
      key: '6_months',
      title: '6 Months',
      durationMonths: 6,
      defaultPrice: 150,
      subtitle: 'Semester prep',
    ),
    SubscriptionPlan(
      key: '1_year',
      title: '1 Year',
      durationMonths: 12,
      defaultPrice: 250,
      subtitle: 'Full exam prep',
      isFeatured: true,
      badgeText: '⭐ Best Value',
    ),
    SubscriptionPlan(
      key: '2_years',
      title: '2 Years',
      durationMonths: 24,
      defaultPrice: 400,
      subtitle: 'Grades 11 & 12',
    ),
    SubscriptionPlan(
      key: '3_years',
      title: '3 Years',
      durationMonths: 36,
      defaultPrice: 550,
      subtitle: 'Grades 10 – 12',
    ),
    SubscriptionPlan(
      key: '4_years',
      title: '4 Years',
      durationMonths: 48,
      defaultPrice: 650,
      subtitle: 'Full High School',
    ),
  ];

  /// The 1-year plan (pre-selected default).
  static SubscriptionPlan get featured =>
      all.firstWhere((p) => p.isFeatured, orElse: () => all[1]);

  /// Look up a plan by key; returns null for legacy rows with no plan.
  static SubscriptionPlan? byKey(String? key) {
    if (key == null || key.isEmpty) return null;
    try {
      return all.firstWhere((p) => p.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Human-readable label from a key (used in admin).
  static String labelOf(String? key) => byKey(key)?.title ?? key ?? '—';

  @override
  bool operator ==(Object other) =>
      other is SubscriptionPlan && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
