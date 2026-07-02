import 'package:hive_ce_flutter/adapters.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/vault_v1.dart';

late final String appId;
late final SharedPreferences prefs;

Future<Box<T>> getBox<T>(String name) async =>
    Hive.isBoxOpen(name)
        ? Hive.box<T>(name)
        : await Hive.openBox<T>(name);

Future<Box<AccountV1>> getAccountsV1Box() async => await getBox<AccountV1>('beshence_${appId}_accounts_v1');
Future<Box<VaultV1>> getVaultsV1Box() async => await getBox<VaultV1>('beshence_${appId}_vaults_v1');