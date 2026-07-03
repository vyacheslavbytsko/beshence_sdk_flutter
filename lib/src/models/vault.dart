import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:hive_ce/hive.dart';

import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class BeshenceVault {
  final String id;
  final BeshenceAccount account;

  BeshenceVault({required this.id, required this.account});
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