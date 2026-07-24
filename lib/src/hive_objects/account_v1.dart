import 'package:hive_ce/hive.dart';

part 'account_v1.g.dart';

@HiveType(typeId: 27462)
class AccountV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? oauthTokenId;

  AccountV1({required this.id, required this.oauthTokenId});
}