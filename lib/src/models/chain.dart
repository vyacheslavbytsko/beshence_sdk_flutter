import 'dart:convert';

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

    var eventBase64 = base64UrlEncode(utf8.encode(jsonEncode(mapper.toJson(event))));
    var eventV1 = EventV1(
      id: Uuid().v4(),
        chainName: name,
        name: mapper.name,
        parentId: (await lastEvent)?.id,
        payload: eventBase64,
        applied: applied
    );
    await eventsV1Box.put(encodeKey(accountId: account.id, chainName: name, eventId: eventV1.id), eventV1);
  }

  Future<BeshenceEvent> getEvent(String eventId) async {
    if(!initialized) throw Exception("Beshence not initialized");
    EventV1 boxEvent = eventsV1Box.get(encodeKey(accountId: account.id, chainName: name, eventId: eventId))!;

    final json = jsonDecode(utf8.decode(base64Url.decode(boxEvent.payload)));
    final mapper = eventsRegistry.mapperForName(boxEvent.name);
    final event = mapper.fromJson(json);

    return event;
  }

  Future<BeshenceEvent?> get lastEvent async {
    if(!initialized) throw Exception("Beshence not initialized");
    var eventId = chainsV1Box.get(encodeKey(accountId: account.id, chainName: name))?.lastEventId;
    return eventId == null ? null : await getEvent(eventId);
  }
}