import 'package:equatable/equatable.dart';

// A single entry in a remote directory. Deliberately free of dartssh2 types so
// the browser never depends on the SSH library.
class RemoteFile extends Equatable {
  final String name;
  final String path;
  final bool isDirectory;
  final bool isLink;
  final int size;
  final DateTime? modified;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.isLink,
    required this.size,
    this.modified,
  });

  bool get isHidden => name.startsWith('.');

  @override
  List<Object?> get props => [path, isDirectory, isLink, size, modified];
}
