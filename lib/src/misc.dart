import 'package:hive_ce_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/vault_v1.dart';

late final String appId;
late final SharedPreferences prefs;

bool initialized = false;
late final Box settingsBox;
late final Box<AccountV1> accountsV1Box;
late final Box<VaultV1> vaultsV1Box;
late final Box<ChainV1> chainsV1Box;

/*Future<Box<AccountV1>> getAccountsV1Box() async => await getBox<AccountV1>('${prefix}_accounts_v1');
Future<Box<VaultV1>> getVaultsV1Box() async => await getBox<VaultV1>('${prefix}_vaults_v1');
Future<Box<ChainV1>> getChainsV1Box() async => await getBox<ChainV1>('${prefix}_chains_v1');*/