String formatBytes(int bytes) {
  if (bytes < 1024) return "$bytes B";
  const units = ["KB", "MB", "GB", "TB"];
  var size = bytes / 1024;
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return "${size.toStringAsFixed(size >= 10 ? 0 : 1)} ${units[unit]}";
}
