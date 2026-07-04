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
    var boxEvent = EventV1(
      id: Uuid().v4(),
        chainName: name,
        name: mapper.name,
        parentId: lastEvent?.eventId,
        payload: payload,
        applied: applied
    );
    await eventsV1Box.put(encodeKey(accountId: account.id, chainName: name, eventId: boxEvent.id), boxEvent);

    final boxChainKey = encodeKey(accountId: account.id, chainName: name);
    final boxChain = chainsV1Box.get(boxChainKey)!;
    final newBoxChain = ChainV1(
        name: boxChain.name,
        accountId: boxChain.accountId,
      lastEventId: boxEvent.id
    );
    await chainsV1Box.put(boxChainKey, newBoxChain);
  }

  BeshenceEvent getEvent(String eventId) {
    if(!initialized) throw Exception("Beshence not initialized");
    EventV1 boxEvent = eventsV1Box.get(encodeKey(accountId: account.id, chainName: name, eventId: eventId))!;

    final json = jsonDecode(utf8.decode(base64Url.decode(boxEvent.payload)));
    final mapper = eventsRegistry.mapperForName(boxEvent.name);
    final event = mapper.fromJson(json);
    event.eventId = boxEvent.id;

    return event;
  }

  BeshenceEvent? get lastEvent {
    if(!initialized) throw Exception("Beshence not initialized");
    var eventId = chainsV1Box.get(encodeKey(accountId: account.id, chainName: name))?.lastEventId;
    return eventId == null ? null : getEvent(eventId);
  }
}