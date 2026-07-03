import 'chain.dart';

abstract class BeshenceEvent<T extends BeshenceEvent<T>> {
  final String id;
  final BeshenceChain? chain;

  BeshenceEvent({required this.id, this.chain});

  T fromJson(Map<String, dynamic> json);

  Map<String, dynamic> toJson();
}