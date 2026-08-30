class DurationUtils {
  /// Format a Duration object into MM:SS or HH:MM:SS format.
  static String formatDuration(Duration duration) {
    if (duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    if (hours > 0) {
      final hoursStr = hours.toString().padLeft(2, '0');
      return '$hoursStr:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  /// Parses various timestamp formats returned by V-Modal API rows into a [Duration].
  /// Supports:
  /// - ts_unix_13digits / timestamp_ms (milliseconds integer/string)
  /// - timestamp_sec / time_offset / start_time (seconds float/int/string)
  /// - ISO strings / duration strings
  static Duration parseTimestampToDuration(dynamic timestampValue) {
    if (timestampValue == null) return Duration.zero;

    if (timestampValue is num) {
      if (!timestampValue.isFinite || timestampValue <= 0) return Duration.zero;
      // If greater than 100,000, treat as milliseconds, otherwise seconds
      if (timestampValue > 100000) {
        return Duration(milliseconds: timestampValue.toInt());
      } else {
        return Duration(milliseconds: (timestampValue * 1000).toInt());
      }
    }

    final str = '$timestampValue'.trim();
    if (str.isEmpty) return Duration.zero;

    // Try parsing numeric string
    final numValue = double.tryParse(str);
    if (numValue != null) {
      if (numValue > 100000) {
        return Duration(milliseconds: numValue.toInt());
      } else {
        return Duration(milliseconds: (numValue * 1000).toInt());
      }
    }

    // Try parsing HH:MM:SS or MM:SS format
    final parts = str.split(':');
    if (parts.length == 2) {
      final mins = int.tryParse(parts[0]) ?? 0;
      final secs = double.tryParse(parts[1]) ?? 0;
      return Duration(milliseconds: (mins * 60 * 1000 + secs * 1000).toInt());
    } else if (parts.length == 3) {
      final hrs = int.tryParse(parts[0]) ?? 0;
      final mins = int.tryParse(parts[1]) ?? 0;
      final secs = double.tryParse(parts[2]) ?? 0;
      return Duration(
        milliseconds: (hrs * 3600 * 1000 + mins * 60 * 1000 + secs * 1000).toInt(),
      );
    }

    return Duration.zero;
  }
}
