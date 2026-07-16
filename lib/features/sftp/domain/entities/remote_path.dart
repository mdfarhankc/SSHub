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
}
