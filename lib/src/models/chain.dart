import 'dart:convert';

import 'package:beshence_sdk_flutter/src/hive_objects/chain_v1.dart';
import 'package:uuid/uuid.dart';

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/event_v1.dart';
import '../misc.dart';

class BeshenceChain {
  final String name;
  final BeshenceAccount account;

  BeshenceChain({required this.name, required this.account});

  Future<void> addEvent(BeshenceEvent event, {bool applied = true}) async {
    if(!initialized) throw Exception("Beshence not initialized");

    final mapper = eventsRegistry.mapperForType(event.runtimeType);

    var payload = base64UrlEncode(utf8.encode(jsonEncode(mapper.toJson(event))));
    var eventV1 = EventV1(
        id: Uuid().v4(),
        chainName: name,
        name: mapper.name,
        tempParentId: lastEvent?.id,
        permParentId: null,
        payload: payload,
        applied: applied
    );
    await eventsV1Box.put(encodeKey(accountId: account.id, chainName: name, eventId: eventV1.id), eventV1);

    final chainV1key = encodeKey(accountId: account.id, chainName: name);
    final chainV1 = chainsV1Box.get(chainV1key)!;
    final newBoxChain = ChainV1(
        name: chainV1.name,
        accountId: chainV1.accountId,
      lastEventId: eventV1.id
    );
    await chainsV1Box.put(chainV1key, newBoxChain);
  }

  BeshenceEvent getEvent(String eventId) {
    if(!initialized) throw Exception("Beshence not initialized");
    EventV1 eventV1 = eventsV1Box.get(encodeKey(accountId: account.id, chainName: name, eventId: eventId))!;

    final json = jsonDecode(utf8.decode(base64Url.decode(eventV1.payload)));
    final mapper = eventsRegistry.mapperForName(eventV1.name);
    final event = mapper.fromJson(json);
    event.id = eventV1.id;
    event.chain = this;
    event.account = account;

    return event;
  }

  BeshenceEvent? get lastEvent {
    if(!initialized) throw Exception("Beshence not initialized");
    var eventId = chainsV1Box.get(encodeKey(accountId: account.id, chainName: name))?.lastEventId;
    return eventId == null ? null : getEvent(eventId);
  }

  BeshenceRemoteChain remote(BeshenceVault vault) => BeshenceRemoteChain(vault: vault, chain: this);
}