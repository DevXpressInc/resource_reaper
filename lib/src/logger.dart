import 'dart:developer';

enum Level {
  debug(500, '🔍'),
  info(800, '💡'),
  warning(900, '⚠️');

  const Level(this.value, this.emoji);

  final int value;

  final String emoji;
}


void reaperLog(String message, [Level logLevel = Level.info]) {
  log(
    '${logLevel.emoji} $message',
    name: 'Resource Reaper',
    level: logLevel.value,
  );
}