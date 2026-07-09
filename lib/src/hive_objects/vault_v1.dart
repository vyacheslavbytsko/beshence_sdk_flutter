import 'package:hive_ce/hive.dart';

part 'vault_v1.g.dart';

@HiveType(typeId: 27464)
class VaultV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String accountId;
  @HiveField(2)
  final String bankId;
  @HiveField(6)
  final int priority;

  VaultV1({
    required this.id,
    required this.accountId,
    required this.bankId,
    required this.priority
  });
}