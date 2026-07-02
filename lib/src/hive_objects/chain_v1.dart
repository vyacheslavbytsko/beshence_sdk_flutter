import 'package:hive_ce/hive.dart';

part 'chain_v1.g.dart';

@HiveType(typeId: 27464)
class ChainV1 extends HiveObject {
  @HiveField(0)
  final String name;
  @HiveField(1)
  final String vaultId;

  ChainV1({required this.name, required this.vaultId});
}