part of 'file_viewer_cubit.dart';

enum FileViewerStatus { loading, ready, binary, failure }

class FileViewerState extends Equatable {
  final FileViewerStatus status;
  final String text;
  final bool truncated;
  final String? errorMessage;
  final bool saving;
  final String? saveError;

  const FileViewerState({
    this.status = FileViewerStatus.loading,
    this.text = "",
    this.truncated = false,
    this.errorMessage,
    this.saving = false,
    this.saveError,
  });

  FileViewerState copyWith({
    FileViewerStatus? status,
    String? text,
    bool? truncated,
    String? errorMessage,
    bool? saving,
    String? saveError,
  }) => FileViewerState(
    status: status ?? this.status,
    text: text ?? this.text,
    truncated: truncated ?? this.truncated,
    errorMessage: errorMessage ?? this.errorMessage,
    saving: saving ?? this.saving,
    saveError: saveError,
  );

  int get lineCount => text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;

  @override
  List<Object?> get props => [
    status,
    text,
    truncated,
    errorMessage,
    saving,
    saveError,
  ];
}
