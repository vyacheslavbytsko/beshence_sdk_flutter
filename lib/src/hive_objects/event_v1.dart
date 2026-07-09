import 'package:hive_ce/hive.dart';

part 'event_v1.g.dart';

@HiveType(typeId: 27466)
class EventV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String chainName;
  @HiveField(3)
  final String accountId;
  @HiveField(4)
  final String? parentId;
  @HiveField(5)
  final String payload;
  @HiveField(6)
  final bool applied;
  @HiveField(7)
  final bool synced;

  EventV1({
    required this.id,
    required this.name,
    required this.chainName,
    required this.accountId,
    required this.parentId,
    required this.payload,
    required this.applied,
    required this.synced
  });
}