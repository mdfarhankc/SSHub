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
  // Unix permission bits (0-0o777), or null when the server did not report them.
  final int? permissions;
  // Owning user and group ids from the listing, or null when not reported.
  final int? uid;
  final int? gid;

  const RemoteFile({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.isLink,
    required this.size,
    this.modified,
    this.permissions,
    this.uid,
    this.gid,
  });

  bool get isHidden => name.startsWith('.');

  @override
  List<Object?> get props => [
    path,
    isDirectory,
    isLink,
    size,
    modified,
    permissions,
    uid,
    gid,
  ];
}
