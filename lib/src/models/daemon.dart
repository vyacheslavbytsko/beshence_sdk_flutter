import 'dart:async';
import 'account.dart';

enum DaemonState { stopped, starting, running, stopping }

class BeshenceDaemon {
  static final Map<BeshenceAccount, BeshenceDaemon> _daemons = {};
  
  final BeshenceAccount account;
  DaemonState _state = DaemonState.stopped;
  Future<void>? _startFuture;
  Future<void>? _stopFuture;
  Timer? _loopTimer;

  BeshenceDaemon._({required this.account});
  
  factory BeshenceDaemon.of(BeshenceAccount account) {
    if (_daemons.containsKey(account)) {
      return _daemons[account]!;
    } else {
      final daemon = BeshenceDaemon._(account: account);
      _daemons[account] = daemon;
      return daemon;
    }
  }

  Future<void> startDaemon() async {
    if (_state == DaemonState.running) {
      print('[BeshenceDaemon][account:${account.id}] Daemon already running.');
      return;
    }
    if (_state == DaemonState.starting) {
      print('[BeshenceDaemon][account:${account.id}] Daemon already starting; awaiting existing start.');
      return await _startFuture;
    }

    _state = DaemonState.starting;
    _startFuture = _doStartDaemon();

    try {
      await _startFuture;
      _state = DaemonState.running;
    } catch (e) {
      _state = DaemonState.stopped;
      rethrow;
    } finally {
      _startFuture = null;
    }
  }

  Future<void> _doStartDaemon() async {
    print('[BeshenceDaemon][account:${account.id}] Starting Beshence Daemon...');
    _startPrintLoop();
    print('[BeshenceDaemon][account:${account.id}] Beshence Daemon started successfully.');
  }

  void _startPrintLoop() {
    _loopTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (_state != DaemonState.running) return;
      print('1');
    });
  }

  void _stopPrintLoop() {
    _loopTimer?.cancel();
    _loopTimer = null;
  }

  Future<void> stopDaemon() async {
    if (_state == DaemonState.stopped) {
      print('[BeshenceDaemon][account:${account.id}] Daemon already stopped.');
      return;
    }
    if (_state == DaemonState.stopping) {
      print('[BeshenceDaemon][account:${account.id}] Daemon already stopping; awaiting existing stop.');
      return await _stopFuture;
    }

    _state = DaemonState.stopping;
    _stopFuture = _doStopDaemon();

    try {
      await _stopFuture;
      _state = DaemonState.stopped;
    } catch (e) {
      _state = DaemonState.running;
      rethrow;
    } finally {
      _stopFuture = null;
    }
  }

  Future<void> stopDemon() => stopDaemon();

  Future<void> _doStopDaemon() async {
    print('[BeshenceDaemon][account:${account.id}] Stopping Beshence Daemon...');
    _stopPrintLoop();
    await Future.delayed(Duration(milliseconds: 10));
    print('[BeshenceDaemon][account:${account.id}] Beshence Daemon stopped.');
  }

  DaemonState daemonState() => _state;
}