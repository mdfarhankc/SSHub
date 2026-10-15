import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/sftp/domain/entities/remote_file.dart';
import 'package:sshub/features/sftp/domain/repositories/sftp_repository.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';

part 'file_viewer_state.dart';

class FileViewerCubit extends Cubit<FileViewerState> {
  final SftpSession _session;
  final RemoteFile file;

  // Held in memory, so a log or a dump would otherwise take the app down.
  static const maxBytes = 1024 * 1024;

  FileViewerCubit(this._session, this.file) : super(const FileViewerState()) {
    load();
  }

  Future<void> load() async {
    emit(const FileViewerState());
    try {
      final bytes = await _session.readBytes(file, maxBytes: maxBytes);
      if (isClosed) return;
      if (_looksBinary(bytes)) {
        emit(const FileViewerState(status: FileViewerStatus.binary));
        return;
      }
      emit(
        FileViewerState(
          status: FileViewerStatus.ready,
          text: utf8.decode(bytes, allowMalformed: true),
          truncated: file.size > bytes.length,
        ),
      );
    } on SshConnectionException catch (e) {
      appLog("Open file failed", e);
      if (!isClosed) {
        emit(
          FileViewerState(
            status: FileViewerStatus.failure,
            errorMessage: e.message,
          ),
        );
      }
    }
  }

  // Writes [text] back over the file. Refused for truncated or non-text files,
  // since only part of a truncated file is held and would overwrite the rest.
  Future<void> save(String text) async {
    if (state.status != FileViewerStatus.ready || state.truncated) return;
    emit(state.copyWith(saving: true, saveError: null));
    try {
      await _session.writeBytes(file.path, Uint8List.fromList(utf8.encode(text)));
      if (isClosed) return;
      emit(state.copyWith(saving: false, text: text, saveError: null));
    } on SshConnectionException catch (e) {
      appLog("Save file failed", e);
      if (!isClosed) emit(state.copyWith(saving: false, saveError: e.message));
    }
  }

  // A NUL byte does not occur in UTF-8 text. Only the head is checked.
  static bool _looksBinary(Uint8List bytes) {
    final limit = bytes.length < 8000 ? bytes.length : 8000;
    for (var i = 0; i < limit; i++) {
      if (bytes[i] == 0) return true;
    }
    return false;
  }
}
