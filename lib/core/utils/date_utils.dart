import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

/// Utilities for dual calendar (Gregorian/Hijri) support.
class AppDateUtils {
  /// Storage format: "YYYY-MM-DD|gregorian" or "YYYY-MM-DD|hijri"
  static const String formatSeparator = '|';

  /// Formats a date for storage with calendar indicator.
  static String formatForStorage(DateTime date, String calendarMode) {
    if (calendarMode == 'hijri') {
      final hijri = HijriCalendar.fromDate(date);
      final dateStr =
          '${hijri.hYear}-${hijri.hMonth.toString().padLeft(2, '0')}-${hijri.hDay.toString().padLeft(2, '0')}';
      return '$dateStr${formatSeparator}hijri';
    } else {
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      return '$dateStr${formatSeparator}gregorian';
    }
  }

  /// Parses a stored date string into date and format.
  static (String, String) parseFromStorage(String stored) {
    final parts = stored.split(formatSeparator);
    if (parts.length >= 2) {
      return (parts[0], parts[1]);
    }
    return (parts[0], 'gregorian');
  }

  /// Converts stored date string to DateTime.
  static DateTime? parseToDateTime(String stored) {
    final (dateStr, format) = parseFromStorage(stored);

    try {
      if (format == 'hijri') {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          final hijri = HijriCalendar()
            ..hYear = int.parse(parts[0])
            ..hMonth = int.parse(parts[1])
            ..hDay = int.parse(parts[2]);
          return hijri.hijriToGregorian(hijri.hYear, hijri.hMonth, hijri.hDay);
        }
      } else {
        return DateFormat('yyyy-MM-dd').parse(dateStr);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Formats a DateTime for display in Gregorian format.
  static String formatGregorianDisplay(DateTime date, {bool short = false}) {
    if (short) {
      return DateFormat('MMM d, y').format(date);
    }
    return DateFormat('MMMM d, yyyy').format(date);
  }

  /// Formats a DateTime for display in Hijri format.
  static String formatHijriDisplay(DateTime date, {bool short = false}) {
    final hijri = HijriCalendar.fromDate(date);
    if (short) {
      return '${hijri.hDay} ${_getHijriMonthShort(hijri.hMonth)} ${hijri.hYear}';
    }
    return '${hijri.hDay} ${_getHijriMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  /// Gets Hijri equivalent text for a Gregorian date.
  static String getHijriEquivalent(DateTime date) {
    final hijri = HijriCalendar.fromDate(date);
    return '${hijri.hDay} ${_getHijriMonthName(hijri.hMonth)} ${hijri.hYear}';
  }

  /// Gets Gregorian equivalent text for a Hijri date.
  static String getGregorianEquivalent(int hYear, int hMonth, int hDay) {
    final hijri = HijriCalendar()
      ..hYear = hYear
      ..hMonth = hMonth
      ..hDay = hDay;
    final gregorian = hijri.hijriToGregorian(hYear, hMonth, hDay);
    return DateFormat('MMMM d, yyyy').format(gregorian);
  }

  /// Converts Hijri date to Gregorian DateTime.
  static DateTime hijriToGregorian(int hYear, int hMonth, int hDay) {
    final hijri = HijriCalendar()
      ..hYear = hYear
      ..hMonth = hMonth
      ..hDay = hDay;
    return hijri.hijriToGregorian(hYear, hMonth, hDay);
  }

  /// Gets today's date in Hijri format.
  static HijriCalendar getHijriToday() {
    return HijriCalendar.now();
  }

  static String _getHijriMonthName(int month) {
    const months = [
      '',
      'Muharram',
      'Safar',
      "Rabi' al-Awwal",
      "Rabi' al-Thani",
      'Jumada al-Awwal',
      'Jumada al-Thani',
      'Rajab',
      "Sha'ban",
      'Ramadan',
      'Shawwal',
      "Dhu al-Qi'dah",
      'Dhu al-Hijjah',
    ];
    return months[month.clamp(1, 12)];
  }

  static String _getHijriMonthShort(int month) {
    const months = [
      '',
      'Muh.',
      'Saf.',
      'Rab. I',
      'Rab. II',
      'Jum. I',
      'Jum. II',
      'Raj.',
      "Sha.",
      'Ram.',
      'Shaw.',
      "Dhu Q.",
      'Dhu H.',
    ];
    return months[month.clamp(1, 12)];
  }

  /// Gets relative time description (e.g., "2h ago", "Yesterday").
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }
}
