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

    var eventBase64 = base64Encode(utf8.encode(jsonEncode(event.toJson())));
    var eventV1 = EventV1(
      id: Uuid().v4(), chainName: name, name: event.name, payload: eventBase64, applied: applied
    );
    await eventsV1Box.put(encodeKey(accountId: account.id, chainName: name, eventId: eventV1.id), eventV1);
  }
}