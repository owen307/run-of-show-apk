String formatSpan(int seconds) {
  final negative = seconds < 0;
  final value = seconds.abs();
  final hours = value ~/ 3600;
  final minutes = (value % 3600) ~/ 60;
  final secs = value % 60;
  final clock = hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}'
      : '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  return negative ? '+$clock' : clock;
}

String formatMinute(int minute) {
  final clamped = minute.clamp(0, 1439);
  final hour24 = clamped ~/ 60;
  final mins = clamped % 60;
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final suffix = hour24 >= 12 ? 'PM' : 'AM';
  return '$hour:${mins.toString().padLeft(2, '0')} $suffix';
}

String formatWall(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final second = time.second.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute:$second $suffix';
}

String cueNumber(int index) => (index + 1).toString().padLeft(2, '0');

String isoStamp(DateTime time) {
  final utc = time.toUtc();
  String two(int value) => value.toString().padLeft(2, '0');
  String three(int value) => value.toString().padLeft(3, '0');
  return '${utc.year.toString().padLeft(4, '0')}-${two(utc.month)}-${two(utc.day)}'
      'T${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)}.${three(utc.millisecond)}Z';
}

DateTime parseStamp(String value) => DateTime.parse(value).toLocal();

String clipText(String value, int max) {
  final trimmed = value.trim();
  if (trimmed.length <= max) return trimmed;
  return trimmed.substring(0, max);
}
