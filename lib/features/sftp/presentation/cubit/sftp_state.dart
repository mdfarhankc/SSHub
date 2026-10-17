part of 'sftp_cubit.dart';

enum SftpStatus { connecting, ready, failure }

class SftpTransfer extends Equatable {
  final String name;
  final bool isUpload;
  final int transferred;
  final int total;

  // Set for folders, whose size is unknown until the walk ends.
  final String? detail;

  final DateTime startedAt;

  // Only single-file transfers can pause and resume; folders cannot.
  final bool pausable;

  const SftpTransfer({
    required this.name,
    required this.isUpload,
    required this.transferred,
    required this.total,
    required this.startedAt,
    this.detail,
    this.pausable = false,
  });

  Duration get elapsed => DateTime.now().difference(startedAt);

  // Null when the size is unknown, which the UI shows as an indeterminate bar.
  double? get fraction =>
      total <= 0 ? null : (transferred / total).clamp(0.0, 1.0);

  SftpTransfer copyWith({int? transferred, String? detail}) => SftpTransfer(
    name: name,
    isUpload: isUpload,
    transferred: transferred ?? this.transferred,
    total: total,
    startedAt: startedAt,
    detail: detail ?? this.detail,
    pausable: pausable,
  );

  @override
  List<Object?> get props => [
    name,
    isUpload,
    transferred,
    total,
    startedAt,
    detail,
    pausable,
  ];
}

// A transfer the user paused, kept so it can resume from where it stopped.
class PausedTransfer extends Equatable {
  final int id;
  final String name;
  final bool isUpload;
  final int bytesDone;
  final int total;
  const PausedTransfer({
    required this.id,
    required this.name,
    required this.isUpload,
    required this.bytesDone,
    required this.total,
  });

  double? get fraction =>
      total <= 0 ? null : (bytesDone / total).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [id, name, isUpload, bytesDone, total];
}

// A transfer waiting its turn. Holds only what the queue list shows; the work
// to run it lives in the cubit.
class QueuedTransfer extends Equatable {
  final int id;
  final String name;
  final bool isUpload;
  const QueuedTransfer({
    required this.id,
    required this.name,
    required this.isUpload,
  });

  @override
  List<Object?> get props => [id, name, isUpload];
}

class SftpState extends Equatable {
  final SftpStatus status;
  final String path;
  final List<RemoteFile> entries;
  final String? errorMessage;
  final String? noticeMessage;
  final bool showHidden;
  final bool gridView;
  final bool readOnly;
  final bool busy;
  final SftpTransfer? transfer;
  // Transfers waiting behind the active one, drained one at a time.
  final List<QueuedTransfer> queue;
  // Transfers the user paused, resumable from where they stopped.
  final List<PausedTransfer> paused;
  // Whether the search field is open, and the text filtering the listing.
  final bool searching;
  final String searchQuery;
  // Whether selection mode is on, and the paths currently ticked.
  final bool selecting;
  final Set<String> selected;

  const SftpState({
    this.status = SftpStatus.connecting,
    this.path = "",
    this.entries = const [],
    this.errorMessage,
    this.noticeMessage,
    this.showHidden = false,
    this.gridView = false,
    this.readOnly = true,
    this.busy = false,
    this.transfer,
    this.queue = const [],
    this.paused = const [],
    this.searching = false,
    this.searchQuery = "",
    this.selecting = false,
    this.selected = const <String>{},
  });

  bool get isRoot => path == '/';

  List<RemoteFile> get visibleEntries {
    final query = searchQuery.trim().toLowerCase();
    return [
      for (final e in entries)
        if ((showHidden || !e.isHidden) &&
            (query.isEmpty || e.name.toLowerCase().contains(query)))
          e,
    ];
  }

  SftpState copyWith({
    SftpStatus? status,
    String? path,
    List<RemoteFile>? entries,
    String? errorMessage,
    String? noticeMessage,
    bool clearMessages = false,
    bool? showHidden,
    bool? gridView,
    bool? readOnly,
    bool? busy,
    SftpTransfer? transfer,
    bool clearTransfer = false,
    List<QueuedTransfer>? queue,
    List<PausedTransfer>? paused,
    bool? searching,
    String? searchQuery,
    bool? selecting,
    Set<String>? selected,
  }) => SftpState(
    status: status ?? this.status,
    path: path ?? this.path,
    entries: entries ?? this.entries,
    errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
    noticeMessage: clearMessages ? null : (noticeMessage ?? this.noticeMessage),
    showHidden: showHidden ?? this.showHidden,
    gridView: gridView ?? this.gridView,
    readOnly: readOnly ?? this.readOnly,
    busy: busy ?? this.busy,
    transfer: clearTransfer ? null : (transfer ?? this.transfer),
    queue: queue ?? this.queue,
    paused: paused ?? this.paused,
    searching: searching ?? this.searching,
    searchQuery: searchQuery ?? this.searchQuery,
    selecting: selecting ?? this.selecting,
    selected: selected ?? this.selected,
  );

  @override
  List<Object?> get props => [
    status,
    path,
    entries,
    errorMessage,
    noticeMessage,
    showHidden,
    gridView,
    readOnly,
    busy,
    transfer,
    queue,
    paused,
    searching,
    searchQuery,
    selecting,
    selected,
  ];
}
