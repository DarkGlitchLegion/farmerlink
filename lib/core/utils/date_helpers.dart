/// Formats API dates and timestamps for display without exposing ISO syntax.
String formatReadableDate(
  dynamic value, {
  String fallback = 'Date unavailable',
}) {
  final date = switch (value) {
    DateTime value => value,
    String value => DateTime.tryParse(value),
    _ => null,
  };
  if (date == null) return fallback;

  const months = [
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
  final local = date.toLocal();
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
