import 'package:hive_ce/hive.dart';

part 'event_v1.g.dart';

@HiveType(typeId: 27466)
class EventV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String chainName;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String? tempParentId;
  @HiveField(4)
  final String? permParentId;
  @HiveField(5)
  final String payload;
  @HiveField(6)
  final bool applied;

  EventV1({
    required this.id,
    required this.chainName,
    required this.name,
    required this.tempParentId,
    required this.permParentId,
    required this.payload,
    required this.applied
  });

  String? get parentId => permParentId ?? tempParentId;

}