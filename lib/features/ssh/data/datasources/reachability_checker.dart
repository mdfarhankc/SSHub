import 'dart:io';
import 'package:sshub/core/logging/app_log.dart';

// Plain TCP connect probe, not a full SSH handshake.
class ReachabilityChecker {
  const ReachabilityChecker();

  Future<bool> isReachable(
    String host,
    int port, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      return true;
    } catch (e, st) {
      appLog("Reachability check failed", e, st);
      return false;
    }
  }
}
