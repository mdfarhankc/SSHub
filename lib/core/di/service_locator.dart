import 'package:get_it/get_it.dart';

import 'package:sshub/core/auth/local_auth_service.dart';
import 'package:sshub/core/update/update_service.dart';
import 'package:sshub/features/settings/data/datasources/settings_datasource.dart';
import 'package:sshub/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:sshub/features/settings/data/repositories/backup_repository_impl.dart';
import 'package:sshub/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:sshub/features/settings/domain/repositories/backup_repository.dart';
import 'package:sshub/features/settings/domain/repositories/settings_repository.dart';
import 'package:sshub/features/snippets/data/datasources/snippet_datasource.dart';
import 'package:sshub/features/snippets/data/datasources/snippet_local_datasource.dart';
import 'package:sshub/features/snippets/data/repositories/snippet_repository_impl.dart';
import 'package:sshub/features/snippets/domain/repositories/snippet_repository.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/known_hosts_local_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/reachability_checker.dart';
import 'package:sshub/features/ssh/data/datasources/server_datasource.dart';
import 'package:sshub/features/ssh/data/datasources/server_local_datasource.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_connection_repository_impl.dart';
import 'package:sshub/features/ssh/data/repositories/ssh_repository_impl.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_repository.dart';
import 'package:sshub/features/ssh/domain/usecases/connect_to_server.dart';

final sl = GetIt.instance;

void setupLocator() {
  // Datasources
  sl.registerLazySingleton<ServerDatasource>(
    () => const ServerLocalDatasource(),
  );
  sl.registerLazySingleton<SettingsDatasource>(
    () => const SettingsLocalDatasource(),
  );
  sl.registerLazySingleton<KnownHostsDatasource>(
    () => const KnownHostsLocalDatasource(),
  );
  sl.registerLazySingleton<SnippetDatasource>(
    () => const SnippetLocalDatasource(),
  );
  sl.registerLazySingleton<ReachabilityChecker>(
    () => const ReachabilityChecker(),
  );

  // Repositories
  sl.registerLazySingleton<SshRepository>(() => SshRepositoryImpl(sl()));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SshConnectionRepository>(
    () => SshConnectionRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<SnippetRepository>(
    () => SnippetRepositoryImpl(sl()),
  );
  sl.registerLazySingleton<BackupRepository>(
    () => BackupRepositoryImpl(sl(), sl(), sl()),
  );

  // Services
  sl.registerLazySingleton<LocalAuthService>(() => LocalAuthService());
  sl.registerLazySingleton<UpdateService>(() => UpdateService());

  // Usecases
  sl.registerLazySingleton<ConnectToServer>(() => ConnectToServer(sl()));
}
