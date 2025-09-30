String formatCompact(Duration duration) {
  if (duration.isNegative) {
    return '0m';
  }
  final totalMinutes = duration.inMinutes;
  if (totalMinutes <= 0) {
    return '0m';
  }

  final minutesPerDay = 24 * 60;
  final days = totalMinutes ~/ minutesPerDay;
  final hours = (totalMinutes % minutesPerDay) ~/ 60;
  final minutes = totalMinutes % 60;

  final parts = <String>[];
  if (days > 0) {
    parts.add('d');
    if (hours > 0) {
      parts.add('h');
    } else if (minutes > 0 && parts.length < 2) {
      parts.add('m');
    }
    return parts.join(' ');
  }

  if (hours > 0) {
    parts.add('h');
    if (minutes > 0) {
      parts.add('m');
    }
    return parts.join(' ');
  }

  return 'm';
}
