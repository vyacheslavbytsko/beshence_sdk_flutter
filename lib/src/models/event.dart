abstract class BeshenceEvent {
  String? id;
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
