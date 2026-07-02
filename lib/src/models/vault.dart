import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:hive_ce/hive.dart';

import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class BeshenceVault {
  final String id;

  BeshenceVault({required this.id});

  Future<BeshenceAccount> get account async {
    await Beshence.init();
    final Box<VaultV1> box = await getVaultsV1Box();
    final VaultV1? boxVault = box.get(id);
    if (boxVault == null) throw StateError('Vault not found');
    final String accountId = boxVault.accountId;
    return BeshenceAccount(id: accountId);
  }
}

class BeshenceVaultTokenPair {
  final String refreshToken;
  final String accessToken;

  const BeshenceVaultTokenPair({required this.refreshToken, required this.accessToken});
}

class BeshenceVaultLoginPayload {
  final Map<String, dynamic> payload;

  BeshenceVaultLoginPayload._({required this.payload});

  factory BeshenceVaultLoginPayload.loginAndPassword(String login, String password) {
    return BeshenceVaultLoginPayload._(payload: {
      'method': 'loginAndPassword',
      'login': login,
      'password': password
    });
  }
}