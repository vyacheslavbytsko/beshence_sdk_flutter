import 'chain.dart';

abstract class BeshenceEvent<T extends BeshenceEvent<T>> {
  final String id;
  final BeshenceChain chain;
  final String name;
  final bool applied;

  BeshenceEvent({required this.id, required this.chain, required this.name, required this.applied});

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();
}