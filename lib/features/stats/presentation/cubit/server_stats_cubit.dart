import 'dart:async';
import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/ssh/data/datasources/ssh_client_factory.dart';
import 'package:sshub/features/ssh/domain/entities/ssh_server.dart';
import 'package:sshub/features/ssh/domain/repositories/ssh_connection_repository.dart';
import 'package:sshub/features/stats/domain/entities/server_stats.dart';

class ServerStatsState {
  final ServerStats? stats;
  final bool loading;
  final String? error;
  // True while a poll or reconnect is failing but a last reading is still shown.
  final bool stale;
  const ServerStatsState({
    this.stats,
    this.loading = false,
    this.error,
    this.stale = false,
  });
}

// Opens its own SSH connection to a server and polls it for resource use. CPU
// percent is derived from the change between two /proc/stat samples, so it is
// null on the first reading.
class ServerStatsCubit extends Cubit<ServerStatsState>
    with WidgetsBindingObserver {
  final SshServer server;
  final SshClientFactory _clients;

  SSHClient? _client;
  Timer? _timer;
  bool _busy = false;
  bool _closed = false;
  bool _paused = false;
  bool _connecting = false;
  bool _everConnected = false;
  (int idle, int total)? _prevCpu;

  // Poll this often while healthy; while a reconnect keeps failing, wait
  // _backoff instead and grow it up to _maxBackoff so a down or refusing server
  // is not hammered every few seconds.
  static const _interval = Duration(seconds: 3);
  static const _maxBackoff = Duration(seconds: 60);
  Duration _backoff = _interval;

  ServerStatsCubit(this.server, this._clients)
    : super(const ServerStatsState(loading: true)) {
    WidgetsBinding.instance.addObserver(this);
    _tick();
  }

  // Retry from the error state: reconnect if the connection never opened or
  // has dropped, otherwise just read the next sample.
  Future<void> refresh() async {
    if (_client != null) {
      await _poll();
      return;
    }
    emit(const ServerStatsState(loading: true));
    _backoff = _interval;
    await _tick();
  }

  // Stop polling while the app is not visible, and pick straight back up when
  // it returns, so a backgrounded window is not holding an SSH poll every 3s.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      _paused = false;
      _backoff = _interval;
      if (!_closed) _tick();
    } else if (lifecycle == AppLifecycleState.paused ||
        lifecycle == AppLifecycleState.hidden) {
      _paused = true;
      _prevCpu = null; // a gap makes the next CPU delta meaningless
      _timer?.cancel();
      _timer = null;
    }
  }

  // Reads one sample, or reconnects if the connection is gone, then schedules
  // the next run: soon while healthy, backing off while a reconnect fails.
  Future<void> _tick() async {
    _timer?.cancel();
    _timer = null;
    if (_closed || _paused) return;

    if (_client == null) {
      await _start();
    } else {
      await _poll();
    }
    if (_closed || _paused) return;

    if (_client != null) {
      _backoff = _interval;
      _scheduleNext(_interval);
    } else if (_everConnected) {
      // Dropped after a good connection: keep retrying, but ease off.
      _scheduleNext(_backoff);
      final next = _backoff * 2;
      _backoff = next > _maxBackoff ? _maxBackoff : next;
    }
    // An initial connect that never succeeded stops here and waits for Retry.
  }

  void _scheduleNext(Duration delay) {
    _timer?.cancel();
    if (_closed || _paused) return;
    _timer = Timer(delay, _tick);
  }

  Future<void> _start() async {
    if (_connecting || _closed) return;
    _connecting = true;
    try {
      final client = await _clients.authenticated(
        server,
        password: server.password.isEmpty ? null : server.password,
        privateKey: server.privateKey.isEmpty ? null : server.privateKey,
        keyPassphrase: server.passphrase.isEmpty ? null : server.passphrase,
      );
      if (_closed) {
        client.close();
        return;
      }
      _client = client;
      _everConnected = true;
      await _poll();
    } catch (e, st) {
      appLog("Server stats connect failed", e, st);
      // Keep any last snapshot and mark it stale; only show the error outright
      // when there is nothing on screen yet.
      if (state.stats == null) {
        if (!isClosed) emit(ServerStatsState(error: _message(e)));
      } else {
        _markStale();
      }
    } finally {
      _connecting = false;
    }
  }

  Future<void> _poll() async {
    final client = _client;
    if (client == null || _busy || _closed) return;
    _busy = true;
    try {
      final out = await client
          .run(_command)
          .timeout(const Duration(seconds: 10));
      final stats = _parse(utf8.decode(out, allowMalformed: true));
      if (!isClosed) emit(ServerStatsState(stats: stats));
    } catch (e, st) {
      appLog("Server stats poll failed", e, st);
      // A dead connection is dropped so the next tick reconnects; a merely slow
      // command keeps the last snapshot on screen.
      if (client.isClosed) {
        _client = null;
        _prevCpu = null;
      }
      if (state.stats == null) {
        if (!isClosed) emit(ServerStatsState(error: _message(e)));
      } else {
        _markStale();
      }
    } finally {
      _busy = false;
    }
  }

  void _markStale() {
    if (!isClosed && state.stats != null && !state.stale) {
      emit(ServerStatsState(stats: state.stats, stale: true));
    }
  }

  ServerStats _parse(String output) {
    final parts = output.split('<<>>');
    String sec(int i) => i < parts.length ? parts[i].trim() : '';

    final uptime =
        double.tryParse(sec(3).split(RegExp(r'\s+')).first)?.floor() ?? 0;
    final loadFields = sec(4).split(RegExp(r'\s+'));
    double load(int i) =>
        i < loadFields.length ? (double.tryParse(loadFields[i]) ?? 0) : 0;

    final mem = _memory(sec(7));
    return ServerStats(
      hostname: sec(0),
      kernel: sec(1),
      os: sec(2),
      uptimeSeconds: uptime,
      load1: load(0),
      load5: load(1),
      load15: load(2),
      cores: int.tryParse(sec(5)) ?? 0,
      cpuPercent: _cpuPercent(sec(6)),
      memTotal: mem.memTotal,
      memUsed: mem.memUsed,
      swapTotal: mem.swapTotal,
      swapUsed: mem.swapUsed,
      disks: _disks(sec(8)),
      gpu: _gpu(sec(9)),
      processes: _processes(sec(10)),
    );
  }

  double? _cpuPercent(String statLine) {
    final fields = statLine
        .split(RegExp(r'\s+'))
        .skip(1)
        .map(int.tryParse)
        .toList();
    if (fields.length < 5 || fields.contains(null)) return null;
    final f = fields.cast<int>();
    final idle = f[3] + f[4]; // idle + iowait
    final total = f.reduce((a, b) => a + b);
    final prev = _prevCpu;
    _prevCpu = (idle, total);
    if (prev == null) return null;
    final deltaTotal = total - prev.$2;
    final deltaIdle = idle - prev.$1;
    if (deltaTotal <= 0) return null;
    return (100 * (1 - deltaIdle / deltaTotal)).clamp(0, 100).toDouble();
  }

  // Returns the four memory fields, so the record spreads into ServerStats.
  ({int memTotal, int memUsed, int swapTotal, int swapUsed}) _memory(
    String block,
  ) {
    final values = <String, int>{};
    for (final line in const LineSplitter().convert(block)) {
      final match = RegExp(r'^(\w+):\s+(\d+)').firstMatch(line);
      if (match != null) {
        values[match.group(1)!] = int.parse(match.group(2)!) * 1024;
      }
    }
    final memTotal = values['MemTotal'] ?? 0;
    final memAvailable = values['MemAvailable'] ?? 0;
    final swapTotal = values['SwapTotal'] ?? 0;
    final swapFree = values['SwapFree'] ?? 0;
    return (
      memTotal: memTotal,
      memUsed: (memTotal - memAvailable).clamp(0, memTotal).toInt(),
      swapTotal: swapTotal,
      swapUsed: (swapTotal - swapFree).clamp(0, swapTotal).toInt(),
    );
  }

  List<DiskUsage> _disks(String block) {
    final disks = <DiskUsage>[];
    for (final line in const LineSplitter().convert(block)) {
      final cols = line.trim().split(RegExp(r'\s+'));
      if (cols.length < 3) continue;
      final total = int.tryParse(cols[cols.length - 2]);
      final used = int.tryParse(cols[cols.length - 1]);
      final mount = cols.sublist(0, cols.length - 2).join(' ');
      if (total != null && used != null && total > 0) {
        disks.add(DiskUsage(mount: mount, total: total, used: used));
      }
    }
    disks.sort((a, b) => b.total.compareTo(a.total));
    return disks;
  }

  List<ProcessInfo> _processes(String block) {
    final list = <ProcessInfo>[];
    for (final line in const LineSplitter().convert(block)) {
      // pid, %cpu, %mem are fixed fields; args is last and may hold spaces.
      final cols = line.trim().split(RegExp(r'\s+'));
      if (cols.length < 4) continue;
      final pid = int.tryParse(cols[0]);
      final cpu = double.tryParse(cols[1]);
      final mem = double.tryParse(cols[2]);
      if (pid == null || cpu == null || mem == null) continue;
      final command = cols.sublist(3).join(' ');
      list.add(
        ProcessInfo(
          pid: pid,
          command: command,
          cpuPercent: cpu,
          memPercent: mem,
        ),
      );
    }
    return list;
  }

  GpuUsage? _gpu(String line) {
    if (line.isEmpty) return null;
    final g = line.split(',').map((s) => int.tryParse(s.trim())).toList();
    if (g.length < 3 || g.contains(null)) return null;
    final v = g.cast<int>();
    return GpuUsage(utilPercent: v[0], memUsedMb: v[1], memTotalMb: v[2]);
  }

  String _message(Object e) => e is SshConnectionException
      ? e.message
      : "Could not read server info.";

  @override
  Future<void> close() {
    _closed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _client?.close();
    return super.close();
  }
}

// One shell command gathering every metric; sections split on <<>>. Anything
// missing (nvidia-smi, a field) just parses empty and is hidden.
const _command =
    r'''
hostname; echo '<<>>'
uname -r; echo '<<>>'
(. /etc/os-release 2>/dev/null; echo "$PRETTY_NAME"); echo '<<>>'
cat /proc/uptime; echo '<<>>'
cat /proc/loadavg; echo '<<>>'
nproc; echo '<<>>'
grep '^cpu ' /proc/stat; echo '<<>>'
grep -E 'MemTotal|MemAvailable|SwapTotal|SwapFree' /proc/meminfo; echo '<<>>'
timeout 5 df -B1 --output=target,size,used -x tmpfs -x devtmpfs -x overlay -x squashfs 2>/dev/null | tail -n +2; echo '<<>>'
nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null; echo '<<>>'
ps -eo pid,pcpu,pmem,args --sort=-pcpu 2>/dev/null | grep -v -e '--sort=-pcpu' | head -n 6
''';
