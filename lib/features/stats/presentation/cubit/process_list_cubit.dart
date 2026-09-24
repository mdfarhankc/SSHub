import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/ssh/data/datasources/ssh_client_factory.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/stats/domain/entities/server_stats.dart';

class ProcessListState {
  final List<ProcessInfo> processes;
  final bool loading;
  final bool loadingMore;
  final String? error;
  final int limit;
  final bool hasMore;
  const ProcessListState({
    this.processes = const [],
    this.loading = true,
    this.loadingMore = false,
    this.error,
    this.limit = initialLimit,
    this.hasMore = false,
  });

  static const initialLimit = 10;
}

// Fetches the full process list on demand over its own connection: an initial
// page, then larger pages as the user asks. It does not poll, so it adds no
// steady load beyond the one command per tap.
class ProcessListCubit extends Cubit<ProcessListState> {
  final SshServer server;
  final SshClientFactory _clients;

  SSHClient? _client;
  bool _closed = false;
  bool _busy = false;

  static const _pageSize = 15;

  ProcessListCubit(this.server, this._clients)
    : super(const ProcessListState()) {
    _load(ProcessListState.initialLimit, initial: true);
  }

  Future<void> refresh() => _load(state.limit, initial: false);

  Future<void> loadMore() {
    if (_busy || !state.hasMore) return Future.value();
    return _load(state.limit + _pageSize, initial: false, more: true);
  }

  Future<void> _load(
    int limit, {
    required bool initial,
    bool more = false,
  }) async {
    if (_busy || _closed) return;
    _busy = true;
    if (initial) {
      emit(ProcessListState(
        processes: state.processes,
        loading: true,
        limit: state.limit,
        hasMore: state.hasMore,
      ));
    } else if (more) {
      emit(ProcessListState(
        processes: state.processes,
        loading: false,
        loadingMore: true,
        limit: state.limit,
        hasMore: state.hasMore,
      ));
    }
    try {
      var client = _client;
      if (client == null) {
        client = await _clients.authenticated(
          server,
          password: server.password.isEmpty ? null : server.password,
          privateKey: server.privateKey.isEmpty ? null : server.privateKey,
          keyPassphrase: server.passphrase.isEmpty ? null : server.passphrase,
        );
        _client = client;
      }
      if (_closed) {
        client.close();
        return;
      }
      // Over-fetch by one row so we can tell whether more remain.
      final command =
          "ps -eo pid,pcpu,pmem,rss,args --sort=-pcpu 2>/dev/null "
          "| grep -v -e '--sort=-pcpu' | head -n ${limit + 2}";
      final out = await client.run(command).timeout(const Duration(seconds: 12));
      final rows = _parse(utf8.decode(out, allowMalformed: true));
      if (!isClosed) {
        emit(ProcessListState(
          processes: rows.take(limit).toList(),
          loading: false,
          limit: limit,
          hasMore: rows.length > limit,
        ));
      }
    } catch (e, st) {
      appLog("Process list failed", e, st);
      if (!isClosed) {
        emit(ProcessListState(
          processes: state.processes,
          loading: false,
          error: state.processes.isEmpty ? _message(e) : null,
          limit: state.limit,
          hasMore: state.hasMore,
        ));
      }
    } finally {
      _busy = false;
    }
  }

  List<ProcessInfo> _parse(String block) {
    final list = <ProcessInfo>[];
    for (final line in const LineSplitter().convert(block)) {
      // pid, %cpu, %mem, rss are fixed; args is last and may hold spaces.
      final cols = line.trim().split(RegExp(r'\s+'));
      if (cols.length < 5) continue;
      final pid = int.tryParse(cols[0]);
      final cpu = double.tryParse(cols[1]);
      final mem = double.tryParse(cols[2]);
      final rss = int.tryParse(cols[3]);
      if (pid == null || cpu == null || mem == null || rss == null) continue;
      list.add(ProcessInfo(
        pid: pid,
        command: cols.sublist(4).join(' '),
        cpuPercent: cpu,
        memPercent: mem,
        rssKb: rss,
      ));
    }
    return list;
  }

  String _message(Object e) => e is SshConnectionException
      ? e.message
      : "Could not read processes.";

  @override
  Future<void> close() {
    _closed = true;
    _client?.close();
    return super.close();
  }
}
