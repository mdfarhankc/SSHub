import 'dart:io';

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
    } catch (_) {
      return false;
    }
  }
}
