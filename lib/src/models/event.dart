import 'chain.dart';

abstract class BeshenceEvent<T extends BeshenceEvent<T>> {
  late final String _id;
  late final BeshenceChain _chain;
  final String name;
  late final bool _applied;

  BeshenceEvent({required this.name});

  T fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();

  String get id => _id;
  BeshenceChain get chain => _chain;
  bool get applied => _applied;
}