import 'package:hive_ce/hive.dart';

part 'event_v1.g.dart';

@HiveType(typeId: 27465)
class EventV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String chainId;
  @HiveField(2)
  final String? parentId;
  @HiveField(3)
  final String? sessionId;
  @HiveField(4)
  final String payload;
  @HiveField(5)
  final DateTime locallyCreatedAt;
  @HiveField(6)
  final DateTime createdAt;

  EventV1({
    required this.id,
    required this.chainId,
    this.parentId,
    this.sessionId,
    required this.payload,
    required this.locallyCreatedAt,
    required this.createdAt
  });
}