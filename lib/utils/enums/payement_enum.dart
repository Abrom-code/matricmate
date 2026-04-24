import 'package:flutter/material.dart';

enum PaymentMethod { telebirr, cbe, abyssinia, mpesa }

extension PaymentMethodExtension on PaymentMethod {
  String get title {
    switch (this) {
      case PaymentMethod.telebirr:
        return "Telebirr";
      case PaymentMethod.cbe:
        return "CBE";
      case PaymentMethod.abyssinia:
        return "Abyssinia";
      case PaymentMethod.mpesa:
        return "M-PESA";
    }
  }

  String get subtitle {
    switch (this) {
      case PaymentMethod.telebirr:
        return "Fast mobile payment";
      case PaymentMethod.cbe:
        return "Direct from Commercial Bank";
      case PaymentMethod.abyssinia:
        return "Direct from Abyssinia Bank";
      case PaymentMethod.mpesa:
        return "M-Pesa Safaricom wallet";
    }
  }

  String get accountName {
    switch (this) {
      case PaymentMethod.telebirr:
      case PaymentMethod.cbe:
      case PaymentMethod.abyssinia:
      case PaymentMethod.mpesa:
        return "Beshasha Desmon";
    }
  }

  String get accountNumber {
    switch (this) {
      case PaymentMethod.telebirr:
        return "0983878287";
      case PaymentMethod.cbe:
        return "1000786878626";
      case PaymentMethod.abyssinia:
        return "187978686";
      case PaymentMethod.mpesa:
        return "0783738782";
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.telebirr:
        return Icons.account_balance_wallet;
      case PaymentMethod.cbe:
      case PaymentMethod.abyssinia:
        return Icons.account_balance;
      case PaymentMethod.mpesa:
        return Icons.account_balance_wallet_outlined;
    }
  }

  bool get isFeatured {
    switch (this) {
      case PaymentMethod.telebirr:
        return true;
      case PaymentMethod.cbe:
      case PaymentMethod.abyssinia:
      case PaymentMethod.mpesa:
        return false;
    }
  }
}
