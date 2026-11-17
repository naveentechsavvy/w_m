import 'package:intl/intl.dart';

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Short time label for a notification card:
///   under 1 hour  -> "Just now" / "5 min ago"
///   today         -> "2h ago"
///   yesterday     -> "9:15 PM"
///   older         -> "12 Nov" (or "12 Nov 2025" if not this year)
String formatNotificationTime(DateTime time, {DateTime? now}) {
  final current = now ?? DateTime.now();
  final diff = current.difference(time);

  // Future times (phone clock slightly behind the server) count as now.
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';

  final today = _startOfDay(current);
  final day = _startOfDay(time);

  if (day == today) return '${diff.inHours}h ago';
  if (day == today.subtract(const Duration(days: 1))) {
    return DateFormat('h:mm a').format(time);
  }
  if (time.year == current.year) return DateFormat('d MMM').format(time);
  return DateFormat('d MMM yyyy').format(time);
}

/// Section heading a notification belongs to:
/// "Today", "Yesterday", "This week" (the 5 days before yesterday),
/// or "Earlier".
String notificationGroupLabel(DateTime time, {DateTime? now}) {
  final today = _startOfDay(now ?? DateTime.now());
  final day = _startOfDay(time);

  if (!day.isBefore(today)) return 'Today'; // includes future times
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (!day.isBefore(today.subtract(const Duration(days: 6)))) {
    return 'This week';
  }
  return 'Earlier';
}
