import 'package:intl/intl.dart';

/// Helper to convert and format Gregorian times into Ethiopian 12-hour cycle time representation.
///
/// Ethiopian Time Rule:
/// - The 12-hour day cycle starts at 7:00 AM Gregorian (1:00 AM Ethiopian) and runs until 6:59 PM (12:59 AM Ethiopian).
/// - The 12-hour night cycle starts at 7:00 PM Gregorian (1:00 PM Ethiopian) and runs until 6:59 AM (12:59 PM Ethiopian).
class EthiopianTimeHelper {
  EthiopianTimeHelper._();

  /// Converts a [DateTime] into Ethiopian 12-hour formatted time (e.g., "9:00 AM" or "1:30 PM").
  ///
  /// [showPeriod]: whether to append AM/PM or Amharic period indicator.
  /// [useAmharic]: if true, uses 'ጠዋት', 'ከሰዓት', 'ማታ', 'ሌሊት' instead of 'AM'/'PM'.
  static String formatEthiopianTime(
    DateTime dateTime, {
    bool showPeriod = true,
    bool useAmharic = false,
  }) {
    final local = dateTime.toLocal();
    final hour = local.hour;
    final minute = local.minute;
    final minuteStr = minute.toString().padLeft(2, '0');

    int ethHour;
    String period;

    if (hour >= 7 && hour <= 18) {
      // Daytime (AM): 7 AM (hour 7) -> 1 AM ... 6 PM (hour 18) -> 12 AM
      ethHour = hour - 6;
      period = useAmharic
          ? (ethHour <= 5 ? 'ጠዋት' : 'ከሰዓት')
          : 'AM';
    } else {
      // Nighttime (PM): 7 PM (hour 19) -> 1 PM ... 6 AM (hour 6) -> 12 PM
      ethHour = hour >= 19 ? hour - 18 : hour + 6;
      period = useAmharic
          ? (ethHour <= 5 ? 'ማታ' : 'ሌሊት')
          : 'PM';
    }

    if (!showPeriod) {
      return '$ethHour:$minuteStr';
    }
    return '$ethHour:$minuteStr $period';
  }

  /// Formats both standard time and Ethiopian time side-by-side.
  /// e.g. "3:00 PM (9:00 AM ET)"
  static String formatCombinedTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final gregTime = DateFormat('h:mm a').format(local);
    final ethTime = formatEthiopianTime(local);
    return '$gregTime ($ethTime ET)';
  }

  /// Formats standard date + time with Ethiopian time suffix.
  /// e.g. "Aug 27, 2026 • 4:00 PM (10:00 AM ET)"
  static String formatDateTimeWithEth(
    DateTime dateTime, {
    bool includeYear = true,
  }) {
    final local = dateTime.toLocal();
    final datePattern = includeYear ? 'MMM dd, yyyy' : 'MMM dd';
    final dateStr = DateFormat(datePattern).format(local);
    final gregTime = DateFormat('h:mm a').format(local);
    final ethTime = formatEthiopianTime(local);

    return '$dateStr • $gregTime ($ethTime ET)';
  }

  /// Formats "Closed on MMM dd, yyyy • 4:00 PM (10:00 AM ET)"
  static String formatClosedOn(DateTime dateTime) {
    return 'Closed on ${formatDateTimeWithEth(dateTime, includeYear: true)}';
  }

  /// Formats "Starts: MMM dd, yyyy • 3:00 PM (9:00 AM ET)"
  static String formatStartsAt(DateTime dateTime) {
    return 'Starts: ${formatDateTimeWithEth(dateTime, includeYear: true)}';
  }

  /// Formats "Ends: MMM dd, yyyy • 4:00 PM (10:00 AM ET)"
  static String formatEndsAt(DateTime dateTime) {
    return 'Ends: ${formatDateTimeWithEth(dateTime, includeYear: true)}';
  }
}
