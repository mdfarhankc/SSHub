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

  const SftpTransfer({
    required this.name,
    required this.isUpload,
    required this.transferred,
    required this.total,
    required this.startedAt,
    this.detail,
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
  );

  @override
  List<Object?> get props => [
    name,
    isUpload,
    transferred,
    total,
    startedAt,
    detail,
  ];
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
  });

  bool get isRoot => path == '/';

  List<RemoteFile> get visibleEntries => showHidden
      ? entries
      : [
          for (final e in entries)
            if (!e.isHidden) e,
        ];

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
  ];
}
