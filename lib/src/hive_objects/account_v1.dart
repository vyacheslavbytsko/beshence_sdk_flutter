import 'package:hive_ce/hive.dart';

part 'account_v1.g.dart';

@HiveType(typeId: 27462)
class AccountV1 extends HiveObject {
  @HiveField(0)
  final String id;

  AccountV1({required this.id});
}