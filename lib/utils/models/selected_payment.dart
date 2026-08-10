import 'package:matricmate/data/services/payment_config_service.dart';

/// Wraps a [PaymentConfig] as the currently selected payment method.
/// This replaces the old union of PaymentMethod enum + ExtraPaymentAccount —
/// everything is now a [PaymentConfig] built from the DB.
typedef SelectedPayment = PaymentConfig;
