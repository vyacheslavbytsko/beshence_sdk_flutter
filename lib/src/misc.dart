import 'package:hive_ce_flutter/adapters.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';

bool initialized = false;
late final Box settingsBox;
late final Box<AccountV1> accountsV1Box;
late final Box<VaultV1> vaultsV1Box;
late final Box<ChainV1> chainsV1Box;
late final Box<EventV1> eventsV1Box;

class PingBankResponse {
  final String bankId;
  final List<String> authMethods;

  PingBankResponse({required this.bankId, required this.authMethods});
}

class LoginBankResponse {
  final String refreshToken;
  final String accessToken;

  LoginBankResponse({required this.refreshToken, required this.accessToken});
}

class VaultsResponse {
  final List<Map<String, String>> vaults;

  VaultsResponse({required this.vaults});
}