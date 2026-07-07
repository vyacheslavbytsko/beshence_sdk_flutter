import 'dart:async';
import 'dart:convert';

import '../../beshence_sdk_flutter.dart';

enum DaemonState { stopped, starting, running, stopping }

class BeshenceDaemon {
  static final Map<BeshenceAccount, BeshenceDaemon> _daemons = {};
  
  final BeshenceAccount account;
  DaemonState _state = DaemonState.stopped;
  Future<void>? _startFuture;
  Future<void>? _stopFuture;
  Timer? _loopTimer;
  bool _loopInProgress = false;

  Future<void> _loop(Timer state) async {
    if (_loopInProgress) return;
    _loopInProgress = true;

    try {
      // TODO
      await _pullMany();
      // await _pushOne();
    } finally {
      // notify listeners
      _loopInProgress = false;
    }
  }

  Future<void> _pullMany() async {
    BeshenceVault? onlineVault;
    BeshenceBank? onlineBank;
    String? onlineBankApiUrl;
    for (BeshenceVault vault in account.vaults) {
      if(onlineVault != null) break;
      List<String> onlineBankApiUrls = await vault.bank.onlineApiUrls;
      if(onlineBankApiUrls.isNotEmpty) {
        onlineVault = vault;
        onlineBank = vault.bank;
        onlineBankApiUrl = onlineBankApiUrls.first;
      }
    }

    if(onlineVault == null || onlineBank == null || onlineBankApiUrl == null) return;
    for(BeshenceChain chain in account.chains) {
      try {
        var url = Uri.parse('$onlineBankApiUrl/api/vault/${onlineVault.id}/chain/${chain.name}/event/last');
        var response = await onlineBank.authenticatedHttpGet(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );
        var jsonResponse = jsonDecode(response.body);

        String? lastEventId;

        if(jsonResponse["err"] == "0") {
          lastEventId = jsonResponse["event"]["id"];
        } else if(jsonResponse["err"] == "NO_LAST_EVENT") {
          lastEventId = null;
        } else {
          throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
        }

        print(lastEventId);
      } catch (e) {
        rethrow;
      }
    }
  }

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
    _startLoop();
    print('[BeshenceDaemon][account:${account.id}] Beshence Daemon started successfully.');
  }

  void _startLoop() {
    _loopTimer = Timer.periodic(Duration(seconds: 1), _loop);
  }

  void _stopLoop() {
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
    _stopLoop();
    await Future.delayed(Duration(milliseconds: 10));
    print('[BeshenceDaemon][account:${account.id}] Beshence Daemon stopped.');
  }

  DaemonState daemonState() => _state;
}