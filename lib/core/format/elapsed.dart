String formatElapsed(Duration elapsed) {
  final seconds = elapsed.inSeconds;
  if (seconds < 60) return "${seconds}s";
  final minutes = elapsed.inMinutes;
  if (minutes < 60) return "${minutes}m ${seconds % 60}s";
  return "${elapsed.inHours}h ${minutes % 60}m";
}
