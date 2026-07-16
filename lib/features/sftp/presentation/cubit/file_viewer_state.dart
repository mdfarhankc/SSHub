part of 'file_viewer_cubit.dart';

enum FileViewerStatus { loading, ready, binary, failure }

class FileViewerState extends Equatable {
  final FileViewerStatus status;
  final String text;
  final bool truncated;
  final String? errorMessage;

  const FileViewerState({
    this.status = FileViewerStatus.loading,
    this.text = "",
    this.truncated = false,
    this.errorMessage,
  });

  int get lineCount => text.isEmpty ? 0 : '\n'.allMatches(text).length + 1;

  @override
  List<Object?> get props => [status, text, truncated, errorMessage];
}
