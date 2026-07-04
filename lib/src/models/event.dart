import 'chain.dart';

/*typedef BeshenceEventFromJson = BeshenceEvent Function(Map<String, dynamic>);
typedef BeshenceEventToJson = Map<String, dynamic> Function(BeshenceEvent);

class BeshenceEventRegistry {
  final _events = <String, Type>{};

  void register<T extends BeshenceEvent<T>>(String name) {
    _events[name] = T;
  }

  Map<String, Type> get events => _events;
}

abstract class BeshenceEvent<T extends BeshenceEvent<T>> {
  late final String _id;
  late final BeshenceChain _chain;
  final String name;
  late final bool _applied;

  BeshenceEvent({required this.name});

  static T fromJson<T extends BeshenceEvent<T>>(Map<String, dynamic> json);
  static Map<String, dynamic> toJson();

  String get id => _id;
  BeshenceChain get chain => _chain;
  bool get applied => _applied;
}*/

abstract class BeshenceEvent {
  late final String _id;

  String get eventId => _id;
}

abstract class BeshenceEventMapper<T extends BeshenceEvent> {
  String get name;

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson(T event);
}

class BeshenceEventRegistry {
  final _byName = <String, BeshenceEventMapper>{};
  final _byType = <Type, BeshenceEventMapper>{};

  void register<T extends BeshenceEvent>(BeshenceEventMapper<T> mapper) {
    _byName[mapper.name] = mapper;
    _byType[T] = mapper;
  }

  BeshenceEventMapper mapperForName(String name) => _byName[name]!;
  BeshenceEventMapper mapperForType(Type t) => _byType[t]!;
}
