// POSIX path maths for remote paths, which are always absolute and always use
// forward slashes regardless of the platform the app runs on.
abstract final class RemotePath {
  static String join(String directory, String name) =>
      directory.endsWith('/') ? '$directory$name' : '$directory/$name';

  static String parentOf(String path) {
    final index = path.lastIndexOf('/');
    if (index <= 0) return '/';
    return path.substring(0, index);
  }

  // A listing entry names one file. A server that returns a name with a path
  // separator or a parent reference is trying to write outside the folder the
  // user chose, so such names never reach the local disk.
  static bool isSafeLocalSegment(String name) =>
      name.isNotEmpty &&
      name != '.' &&
      name != '..' &&
      !name.contains('/') &&
      !name.contains(r'\');
}
