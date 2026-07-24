import 'dart:async';
import 'dart:convert';

import 'package:beshence_sdk_flutter/src/misc.dart';

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/chain_v1.dart';
import '../hive_objects/event_v1.dart';

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
      await _pushOne();
      // await _ensurePermanentParentIDs();
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
      onlineBankApiUrl = await vault.bank.onlineApiUrl;
      if(onlineBankApiUrl != null) {
        onlineVault = vault;
        onlineBank = vault.bank;
        break;
      }
    }

    if(onlineVault == null || onlineBank == null || onlineBankApiUrl == null) return;

    for(BeshenceChain chain in account.chains) {
      try {
        String? localLastEventId = chain.lastEvent?.id;
        String? localLastSyncedEventId = localLastEventId;

        // seeking last event that was actually sent to vaults. localLastEventId is also for local-only events!
        while(localLastSyncedEventId != null && eventsV1Box.get(encodeKey(accountId: account.id, chainName: chain.name, eventId: localLastSyncedEventId))!.synced == false) {
          //print("while is true with $localLastSyncedEventId in chain ${chain.name}. ${eventsV1Box.get(encodeKey(accountId: account.id, chainName: chain.name, eventId: localLastSyncedEventId))!.parentId}");
          localLastSyncedEventId = eventsV1Box.get(encodeKey(accountId: account.id, chainName: chain.name, eventId: localLastSyncedEventId))?.parentId;
        }

        String? remoteLastEventId = await chain.remote(onlineVault).remoteLastEventId;

        print("localLastEventId: $localLastEventId");
        print("localLastSyncedEventId: $localLastSyncedEventId");
        print("remoteLastEventId: $remoteLastEventId");

        if (localLastSyncedEventId == remoteLastEventId) {
          print("No events to pull");
          continue;
        }

        String? cursor = localLastSyncedEventId;

        while (true) {
          Uri uri = Uri.parse(
            '$onlineBankApiUrl'
                '/vault/${onlineVault.id}'
                '/chain/${chain.name}'
                '/events'
                '${cursor != null ? '?after=$cursor' : ''}',
          );

          //print(uri);

          final response = await onlineVault.bank.authenticatedHttpGet(uri);

          final json = jsonDecode(response.body);

          //print(json);

          if (json["err"] != "0") {
            if(json["err"] == "PARENT_EVENT_NOT_FOUND") {
              // our local chain is fresher than remote chain so wo don't have anything to pull
              break;
            }
            throw Exception(
              'Failed to pull events: ${json["errmsg"]}',
            );
          }

          final List<dynamic> events = json["events"];

          //print(events);

          if (events.isEmpty) {
            break;
          }

          for (final raw in events) {
            final String encodedPayload = raw["payload"];
            final decodedPayload = jsonDecode(utf8.decode(base64.decode(encodedPayload)));
            final String eventName = decodedPayload["n"];
            final dynamic eventPayload = decodedPayload["e"];

            final incomingEventV1 = EventV1(
              id: raw["id"],
              name: eventName,
              chainName: chain.name,
              accountId: account.id,
              parentId: raw["parent_id"],
              payload: base64.encode(utf8.encode(jsonEncode(eventPayload))),
              applied: false,
              synced: true
            );

            print("incoming event! ${incomingEventV1.id}, ${incomingEventV1.parentId}, ${incomingEventV1.synced}");

            // before we add this event, maybe we have event that rely on this parent_id temporarily.
            // or even permanently, which is an error.
            // we should check it and change its parent id to newly coming event id

            // TODO: handle error when some event's permParentId is the same as coming event parent id

            try {
              EventV1 eventV1withIncomingParentId = eventsV1Box.values.where((e) => (
                  e.chainName == chain.name &&
                      e.accountId == account.id &&
                      e.parentId == raw["parent_id"] && e.synced == false
              )).first;

              print("we found event with this exact parent id as incoming event: ${eventV1withIncomingParentId.id} and it was not synced");

              //print("check 1: ${eventsV1Box.get(encodeKey(accountId: account.id, chainName: chain.name, eventId: eventV1withIncomingParentId.id))?.id}");

              EventV1 updatedEventV1 = EventV1(
                  id: eventV1withIncomingParentId.id,
                  name: eventV1withIncomingParentId.name,
                  chainName: eventV1withIncomingParentId.chainName,
                  accountId: eventV1withIncomingParentId.accountId,
                  parentId: incomingEventV1.id,
                  payload: eventV1withIncomingParentId.payload,
                  applied: eventV1withIncomingParentId.applied,
                  synced: eventV1withIncomingParentId.synced // should be false ig
              );

              print("so now this event (${eventV1withIncomingParentId.id}) has this parent: ${updatedEventV1.parentId}");

              await eventsV1Box.put(encodeKey(accountId: account.id, chainName: chain.name, eventId: eventV1withIncomingParentId.id), updatedEventV1);

              //print("just to check it: ${eventsV1Box.get(encodeKey(accountId: account.id, chainName: chain.name, eventId: eventV1withIncomingParentId.id))?.id}");
            } on StateError {
              //print("we didn't find event with this exact parent id as incoming event");
              // we didn't find this event, moving on
            }

            await eventsV1Box.put(encodeKey(accountId: account.id, chainName: chain.name, eventId: incomingEventV1.id), incomingEventV1);

            final chainV1key = encodeKey(accountId: account.id, chainName: chain.name);
            final chainV1 = chainsV1Box.get(chainV1key)!;
            final newBoxChain = ChainV1(
                name: chainV1.name,
                accountId: chainV1.accountId,
                lastEventId: chainV1.lastEventId == incomingEventV1.parentId ? incomingEventV1.id : chainV1.lastEventId
            );
            await chainsV1Box.put(chainV1key, newBoxChain);

            final spec = eventsRegistry.specForName(eventName);
            final typedEvent = spec.fromJson(eventPayload);
            typedEvent.id = incomingEventV1.id;
            typedEvent.account = BeshenceAccount(id: incomingEventV1.accountId);
            typedEvent.chain = BeshenceChain(name: incomingEventV1.chainName, account: account);
            await spec.apply(typedEvent);

            final appliedEventV1 = EventV1(
                id: incomingEventV1.id,
                name: incomingEventV1.name,
                chainName: incomingEventV1.chainName,
                accountId: incomingEventV1.accountId,
                parentId: incomingEventV1.parentId,
                payload: incomingEventV1.payload,
                applied: true,
                synced: incomingEventV1.synced
            );

            await eventsV1Box.put(encodeKey(accountId: account.id, chainName: chain.name, eventId: incomingEventV1.id), appliedEventV1);

            cursor = incomingEventV1.id;
          }

          if (events.length < 100) {
            break;
          }
        }
      } catch(e) {
        rethrow;
      }
    }
  }

  Future<void> _pushOne() async {
    for(BeshenceVault vault in account.vaults) {
      String? onlineBankApiUrl = await vault.bank.onlineApiUrl;
      if(onlineBankApiUrl == null) break;

      for(BeshenceChain chain in account.chains) {
        try {
          String? remoteLastEventId = await chain.remote(vault).remoteLastEventId;
          String? localLastEventId = chain.lastEvent?.id;

          print("localLastEventId: $localLastEventId");
          print("remoteLastEventId: $remoteLastEventId");

          if(localLastEventId != remoteLastEventId) {
            EventV1 childEventV1 = eventsV1Box.values.where((e) => (
                e.chainName == chain.name &&
                    e.accountId == account.id &&
                    e.parentId == remoteLastEventId
            )).first;
            print("childEvent ${childEventV1.id}");
            BeshenceEvent childEvent = chain.getEvent(childEventV1.id);
            chain.remote(vault).pushEvent(childEvent);
          } else {
            print("No events to push");
          }
        } catch(e) {
          // rethrow;
        }
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