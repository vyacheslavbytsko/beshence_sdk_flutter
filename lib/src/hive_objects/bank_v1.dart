import 'package:hive_ce/hive.dart';

part 'bank_v1.g.dart';

@HiveType(typeId: 27463)
class BankV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  List<String>? apiUrls;
  @HiveField(2)
  String accessToken;
  @HiveField(3)
  String refreshToken;

  BankV1({
    required this.id,
    required this.apiUrls,
    required this.accessToken,
    required this.refreshToken
  });
}