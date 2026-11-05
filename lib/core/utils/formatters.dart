/// Turns dates into short, friendly text.
class Formatters {
  Formatters._();

  static const _months = [
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

  static String _two(int n) => n.toString().padLeft(2, '0');

  static String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day} ${_months[time.month - 1]}';
  }

  /// "3 Nov, 08:10"
  static String dateTime(DateTime time) =>
      '${time.day} ${_months[time.month - 1]}, ${_two(time.hour)}:${_two(time.minute)}';
}
