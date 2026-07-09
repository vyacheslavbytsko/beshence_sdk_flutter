import 'dart:async';
import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/misc.dart';

import '../hive_objects/event_v1.dart';

abstract class BeshenceEvent {
  String? id;
  BeshenceAccount? account;
  BeshenceChain? chain;

  BeshenceEvent? get parent {
    EventV1 eventV1 = eventsV1Box.get(encodeKey(accountId: account!.id, chainName: chain!.name, eventId: id))!;
    EventV1? parentEventV1 = eventsV1Box.get(encodeKey(accountId: account!.id, chainName: chain!.name, eventId: eventV1.parentId));
    if(parentEventV1 == null) return null;
    final parentEventPayload = jsonDecode(utf8.decode(base64.decode(parentEventV1.payload)));
    final parentMapper = eventsRegistry.specForName(parentEventV1.name);
    final parentEvent = parentMapper.fromJson(parentEventPayload);
    parentEvent.id = parentEventV1.id;
    parentEvent.chain = chain;
    parentEvent.account = account;
    return parentEvent;
  }
}

abstract class BeshenceEventSpec<T extends BeshenceEvent> {
  String get name;

  FutureOr<void> apply(T event);

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson(T event);
}

class BeshenceEventRegistry {
  final _byName = <String, BeshenceEventSpec>{};
  final _byType = <Type, BeshenceEventSpec>{};

  void register<T extends BeshenceEvent>(BeshenceEventSpec<T> mapper) {
    _byName[mapper.name] = mapper;
    _byType[T] = mapper;
  }

  BeshenceEventSpec specForName(String name) => _byName[name]!;
  BeshenceEventSpec specForType(Type t) => _byType[t]!;
}
