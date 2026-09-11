import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sshub/core/logging/app_log.dart';
import 'package:sshub/features/ssh/presentation/cubit/terminal_cubit.dart';

enum WorkflowResult { completed, timedOut, cancelled, notConnected }

class WorkflowRunProgress {
  final int step;
  final int total;
  final bool waiting;
  final String label;
  const WorkflowRunProgress({
    required this.step,
    required this.total,
    required this.waiting,
    required this.label,
  });
}

// Runs a resolved workflow against one terminal session: sends a step, and for
// steps that wait, watches the shell output until the expected text appears
// before sending. Each step's text is followed by a carriage return.
//
// One observer runs for the whole workflow so output between steps is never
// lost, and a cursor advances past each match so a later step cannot match a
// prompt an earlier step already consumed.
class WorkflowRunner {
  final TerminalCubit session;
  WorkflowRunner(this.session);

  static const _stepTimeout = Duration(seconds: 10);
  static const _settle = Duration(milliseconds: 150);
  static const _maxBuffer = 16384;

  final ValueNotifier<WorkflowRunProgress?> progress = ValueNotifier(null);

  bool _running = false;
  bool _cancelled = false;
  bool _disposed = false;

  String _buffer = '';
  int _cursor = 0;
  String? _pendingNeedle;
  Completer<bool>? _pendingCompleter;
  void Function(String)? _observer;

  bool get isRunning => _running;

  void _setProgress(WorkflowRunProgress? value) {
    if (!_disposed) progress.value = value;
  }

  bool _scan() {
    final needle = _pendingNeedle;
    if (needle == null) return false;
    final idx = _buffer.toLowerCase().indexOf(needle, _cursor);
    if (idx == -1) return false;
    _cursor = idx + needle.length;
    return true;
  }

  void _onOutput(String data) {
    _buffer += data;
    if (_buffer.length > _maxBuffer) {
      final drop = _buffer.length - _maxBuffer;
      _buffer = _buffer.substring(drop);
      _cursor = (_cursor - drop).clamp(0, _buffer.length);
    }
    final completer = _pendingCompleter;
    if (completer != null && !completer.isCompleted && _scan()) {
      completer.complete(true);
    }
  }

  Future<WorkflowResult> run(
    String label,
    List<({String expect, String send})> steps,
  ) async {
    if (_running) return WorkflowResult.cancelled;
    if (!session.isConnected) return WorkflowResult.notConnected;
    _running = true;
    _cancelled = false;
    _buffer = '';
    _cursor = 0;
    _observer = _onOutput;
    session.addOutputObserver(_onOutput);
    try {
      for (var i = 0; i < steps.length; i++) {
        if (_cancelled) return WorkflowResult.cancelled;
        final step = steps[i];
        final expect = step.expect.trim();
        if (expect.isNotEmpty) {
          _setProgress(
            WorkflowRunProgress(
              step: i,
              total: steps.length,
              waiting: true,
              label: label,
            ),
          );
          final matched = await _awaitPattern(expect);
          if (_cancelled) return WorkflowResult.cancelled;
          if (!matched) {
            appLog(
              "Workflow '$label' timed out at step ${i + 1} waiting for: $expect",
            );
            return WorkflowResult.timedOut;
          }
        }
        if (_cancelled) return WorkflowResult.cancelled;
        _setProgress(
          WorkflowRunProgress(
            step: i,
            total: steps.length,
            waiting: false,
            label: label,
          ),
        );
        session.sendInput(step.send);
        session.sendInput('\r');
        await Future.delayed(_settle);
      }
      return WorkflowResult.completed;
    } finally {
      _running = false;
      _teardown();
      _setProgress(null);
    }
  }

  Future<bool> _awaitPattern(String pattern) async {
    _pendingNeedle = pattern.toLowerCase();
    // The prompt may already be in the buffer: it can arrive between steps.
    if (_scan()) {
      _pendingNeedle = null;
      return true;
    }
    final completer = Completer<bool>();
    _pendingCompleter = completer;
    final timer = Timer(_stepTimeout, () {
      if (!completer.isCompleted) completer.complete(false);
    });
    try {
      return await completer.future;
    } finally {
      timer.cancel();
      _pendingCompleter = null;
      _pendingNeedle = null;
    }
  }

  void cancel() {
    _cancelled = true;
    final completer = _pendingCompleter;
    if (completer != null && !completer.isCompleted) completer.complete(false);
  }

  void _teardown() {
    final observer = _observer;
    if (observer != null) {
      session.removeOutputObserver(observer);
      _observer = null;
    }
  }

  void dispose() {
    _disposed = true;
    cancel();
    _teardown();
    progress.dispose();
  }
}
