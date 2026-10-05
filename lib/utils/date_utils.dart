/// Comprehensive Date, Time, and Duration utility functions for Masti Adda app.
class AppDateUtils {
  AppDateUtils._();

  static const List<String> monthsFull = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> monthsShort = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static const List<String> daysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> daysShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Safely parses a [dynamic] input (DateTime, ISO-8601 String, etc.) into a [DateTime].
  /// Returns null if parsing fails or input is null.
  static DateTime? parseDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input;
    if (input is String) {
      if (input.trim().isEmpty) return null;
      return DateTime.tryParse(input.trim());
    }
    return null;
  }

  /// Formats date to 'DD-MM-YYYY' (e.g. 17-08-2026).
  /// Safely accepts [DateTime], [String], or [dynamic].
  static String formatDate(dynamic date, {String separator = '-'}) {
    final dt = parseDateTime(date)?.toLocal();
    if (dt == null) {
      if (date is String && date.contains('T')) {
        return date.split('T').first;
      }
      return date?.toString() ?? '';
    }
    final day = dt.day.toString().padLeft(2, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final year = dt.year.toString();
    return '$day$separator$month$separator$year';
  }

  /// Formats date to '17 Aug 2026' or '17 Aug'.
  static String formatDateMedium(dynamic date, {bool includeYear = true}) {
    final dt = parseDateTime(date)?.toLocal();
    if (dt == null) return date?.toString() ?? '';
    final month = monthsShort[dt.month - 1];
    if (includeYear) {
      return '${dt.day} $month ${dt.year}';
    }
    return '${dt.day} $month';
  }

  /// Formats date to 'August 17, 2026'.
  static String formatDateFull(dynamic date) {
    final dt = parseDateTime(date)?.toLocal();
    if (dt == null) return date?.toString() ?? '';
    final month = monthsFull[dt.month - 1];
    return '$month ${dt.day}, ${dt.year}';
  }

  /// Formats relative time (e.g. 'Just now', '5m ago', '2h ago', 'Yesterday', '3d ago', '17 Aug').
  static String formatTimeAgo(dynamic rawTime) {
    final dt = parseDateTime(rawTime)?.toLocal();
    if (dt == null) return rawTime?.toString() ?? '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.isNegative) {
      return 'Just now';
    }
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 365) {
      final month = monthsShort[dt.month - 1];
      return '${dt.day} $month';
    } else {
      final month = monthsShort[dt.month - 1];
      return '${dt.day} $month ${dt.year}';
    }
  }

  /// Formats [Duration] into digital clock format:
  /// - 'MM:SS' if hours == 0 (e.g. '04:15')
  /// - 'H:MM:SS' if hours > 0 (e.g. '1:04:15')
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formats seconds integer into digital clock format (e.g. '04:15' or '1:04:15').
  static String formatDurationSeconds(int totalSeconds) {
    if (totalSeconds <= 0) return '00:00';
    return formatDuration(Duration(seconds: totalSeconds));
  }

  /// Formats total minutes to human-readable format (e.g. '1h 45m' or '45m').
  static String formatMinutesToHours(int totalMinutes) {
    if (totalMinutes <= 0) return '0m';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0 && mins > 0) {
      return '${hours}h ${mins}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${mins}m';
    }
  }

  /// Formats time in 12-hour format with AM/PM (e.g. '02:30 PM').
  static String formatTime12Hour(dynamic date) {
    final dt = parseDateTime(date)?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  /// Formats time in 24-hour format (e.g. '14:30').
  static String formatTime24Hour(dynamic date) {
    final dt = parseDateTime(date)?.toLocal();
    if (dt == null) return '';
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Returns contextual greeting based on current time of day:
  /// - Morning (5 AM - 11:59 AM): 'Good morning'
  /// - Afternoon (12 PM - 4:59 PM): 'Good afternoon'
  /// - Evening (5 PM - 8:59 PM): 'Good evening'
  /// - Night (9 PM - 4:59 AM): 'Good evening'
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return 'Good morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Calculates remaining days from now until [endDate].
  /// Returns 0 if already expired or null.
  static int getRemainingDays(dynamic endDate) {
    final dt = parseDateTime(endDate)?.toLocal();
    if (dt == null) return 0;
    final now = DateTime.now();
    final difference = dt.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top-Level Helper Functions (for quick and convenient imports)
// ─────────────────────────────────────────────────────────────────────────────

/// Formats date to 'DD-MM-YYYY' (e.g. 17-08-2026).
String formatDate(dynamic date, {String separator = '-'}) =>
    AppDateUtils.formatDate(date, separator: separator);

/// Formats date to '17 Aug 2026'.
String formatDateMedium(dynamic date, {bool includeYear = true}) =>
    AppDateUtils.formatDateMedium(date, includeYear: includeYear);

/// Formats date to 'August 17, 2026'.
String formatDateFull(dynamic date) => AppDateUtils.formatDateFull(date);

/// Formats relative time (e.g. 'Just now', '5m ago', '2h ago', 'Yesterday', '17 Aug').
String formatTimeAgo(dynamic rawTime) => AppDateUtils.formatTimeAgo(rawTime);

/// Formats [Duration] to 'MM:SS' or 'H:MM:SS'.
String formatDuration(Duration duration) =>
    AppDateUtils.formatDuration(duration);

/// Formats total seconds to 'MM:SS' or 'H:MM:SS'.
String formatDurationSeconds(int totalSeconds) =>
    AppDateUtils.formatDurationSeconds(totalSeconds);

/// Formats minutes to '1h 45m' or '45m'.
String formatMinutesToHours(int totalMinutes) =>
    AppDateUtils.formatMinutesToHours(totalMinutes);
