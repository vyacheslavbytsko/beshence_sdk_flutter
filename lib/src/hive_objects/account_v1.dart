import 'package:beshence_sdk_flutter/src/misc.dart';
import 'package:hive_ce/hive.dart';

part 'account_v1.g.dart';

@HiveType(typeId: 27462)
class AccountV1 extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String? oauthTokenId;
  @HiveField(2)
  final String? name;

  AccountV1({required this.id, required this.oauthTokenId, this.name});

  Future<void> update({
    String? id,
    String? oauthTokenId,
    String? name
  }) async {
    AccountV1 newAccountV1 = copyWith(
        id: id,
        oauthTokenId: oauthTokenId,
        name: name
    );
    await accountsV1Box.put(encodeKey(accountId: this.id), newAccountV1);
  }

  AccountV1 copyWith({
    String? id,
    String? oauthTokenId,
    String? name
  }) {
    return AccountV1(
        id: id ?? this.id,
        oauthTokenId: oauthTokenId ?? this.oauthTokenId,
        name: name ?? this.name
    );
  }
}