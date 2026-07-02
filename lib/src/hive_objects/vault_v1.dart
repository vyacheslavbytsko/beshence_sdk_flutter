import 'package:hive_ce/hive.dart';

part 'vault_v1.g.dart';

@HiveType(typeId: 27463)
class VaultV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String accountId;
  @HiveField(2)
  List<String>? apiUrls;
  @HiveField(3)
  String? accessToken;
  @HiveField(4)
  String? refreshToken;

  VaultV1({
    required this.id,
    required this.accountId,
    required this.apiUrls,
    required this.accessToken,
    required this.refreshToken
  });
}