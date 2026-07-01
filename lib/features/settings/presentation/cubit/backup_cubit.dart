import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/backup/backup_crypto.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/presentation/widgets/export_options_dialog.dart';

part 'backup_state.dart';

class BackupCubit extends Cubit<BackupState> {
  final BackupRepository _repository;
  BackupCubit(this._repository) : super(const BackupState());

  Future<void> export(ExportOptions options) async {
    emit(const BackupState(status: BackupStatus.working));
    try {
      final content = await _repository.export(
        includeServers: options.includeServers,
        includeSettings: options.includeSettings,
        includeSnippets: options.includeSnippets,
        passphrase: options.passphrase,
      );
      final path = await FilePicker.platform.saveFile(
        dialogTitle: "Save SSHub backup",
        fileName: options.passphrase != null
            ? "sshub-backup.json"
            : "sshub-backup-plain.json",
        type: FileType.custom,
        allowedExtensions: ["json"],
        bytes: utf8.encode(content),
      );
      if (path == null) {
        emit(const BackupState());
        return;
      }
      // saveFile already writes the bytes on mobile; desktop hands back a path.
      if (!Platform.isAndroid && !Platform.isIOS) {
        await File(path).writeAsString(content);
      }
      emit(const BackupState(status: BackupStatus.exported));
    } catch (_) {
      emit(
        const BackupState(
          status: BackupStatus.failure,
          message: "Export failed",
        ),
      );
    }
  }

  Future<void> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: "Select SSHub backup",
      type: FileType.custom,
      allowedExtensions: ["json"],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null) return;
    final content = utf8.decode(bytes);

    emit(const BackupState(status: BackupStatus.working));
    try {
      if (BackupCrypto.isEncrypted(content)) {
        emit(
          BackupState(
            status: BackupStatus.needsPassphrase,
            pendingImport: content,
          ),
        );
        return;
      }
    } on BackupException catch (e) {
      emit(BackupState(status: BackupStatus.failure, message: e.message));
      return;
    }
    await _import(content, null);
  }

  Future<void> submitPassphrase(String passphrase) async {
    final content = state.pendingImport;
    if (content == null) return;
    await _import(content, passphrase);
  }

  void cancelImport() => emit(const BackupState());

  Future<void> _import(String content, String? passphrase) async {
    emit(const BackupState(status: BackupStatus.working));
    try {
      await _repository.import(content, passphrase);
      emit(const BackupState(status: BackupStatus.imported));
    } on BackupException catch (e) {
      emit(BackupState(status: BackupStatus.failure, message: e.message));
    } catch (_) {
      emit(
        const BackupState(
          status: BackupStatus.failure,
          message: "Import failed",
        ),
      );
    }
  }
}
