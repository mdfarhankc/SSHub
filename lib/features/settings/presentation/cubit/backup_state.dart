part of 'backup_cubit.dart';

enum BackupStatus {
  idle,
  working,
  needsPassphrase,
  exported,
  imported,
  failure,
}

final class BackupState extends Equatable {
  final BackupStatus status;
  final String? pendingImport;
  final String? message;

  const BackupState({
    this.status = BackupStatus.idle,
    this.pendingImport,
    this.message,
  });

  @override
  List<Object?> get props => [status, pendingImport, message];
}
