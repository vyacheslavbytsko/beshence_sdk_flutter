import 'package:hive_ce/hive.dart';

part 'vault_v1.g.dart';

@HiveType(typeId: 27463)
class VaultV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String accountId;
  @HiveField(2)
  final String bankId;
  @HiveField(3)
  List<String>? apiUrls;
  @HiveField(4)
  String? accessToken;
  @HiveField(5)
  String? refreshToken;
  @HiveField(6)
  int priority;

  VaultV1({
    required this.id,
    required this.accountId,
    required this.bankId,
    required this.apiUrls,
    required this.accessToken,
    required this.refreshToken,
    required this.priority
  });
}