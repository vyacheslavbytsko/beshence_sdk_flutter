import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/events/init_account.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../hive_registrar.g.dart';
import 'events/change_vaults_priorities_v1.dart';
import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';
import 'misc.dart';

class Beshence {
  static Future<void> init(BeshenceEventRegistry registry) async {
    if (initialized) return;

    await Hive.initFlutter();
    Hive.registerAdapters();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var appId = packageInfo.packageName;

    String prefix = "beshence_$appId";
    settingsBox = await Hive.openBox('${prefix}_settings');
    accountsV1Box = await Hive.openBox<AccountV1>('${prefix}_accounts_v1');
    banksV1Box = await Hive.openBox<BankV1>('${prefix}_banks_v1');
    vaultsV1Box = await Hive.openBox<VaultV1>('${prefix}_vaults_v1');
    chainsV1Box = await Hive.openBox<ChainV1>('${prefix}_chains_v1');
    eventsV1Box = await Hive.openBox<EventV1>('${prefix}_events_v1');

    eventsRegistry = registry;
    eventsRegistry.register<InitAccountEvent>(InitAccountEventSpec());
    eventsRegistry.register<AddVaultV1Event>(AddVaultV1EventSpec());
    eventsRegistry.register<ChangeVaultsPrioritiesV1Event>(ChangeVaultsPrioritiesV1EventSpec());

    initialized = true;
  }

  static List<BeshenceAccount> get accounts {
    if(!initialized) throw Exception("Beshence not initialized");

    List<AccountV1> boxAccounts = accountsV1Box.values.toList();

    return [for (var account in boxAccounts) BeshenceAccount(id: account.id)];
  }

  static BeshenceAccount? getAccount(String id) {
    if(!initialized) throw Exception("Beshence not initialized");

    final AccountV1? boxAccount = accountsV1Box.get(encodeKey(accountId: id));
    if (boxAccount == null) return null;

    return BeshenceAccount(id: boxAccount.id);
  }

  static Future<BeshenceAccount> createAccount({String? id, bool initAccountEvent = true}) async {
    if(!initialized) throw Exception("Beshence not initialized");

    String finalId;
    if(id == null) {
      String id;
      do {
        id = Uuid().v4();
      } while (accountsV1Box.containsKey(encodeKey(accountId: id)));
      finalId = id;
    } else {
      finalId = id;
    }
    final boxAccount = AccountV1(id: finalId);
    await accountsV1Box.put(encodeKey(accountId: finalId), boxAccount);

    if (!accountsV1Box.containsKey(encodeKey(accountId: finalId))) {
      throw StateError('Couldn\'t save account');
    }

    var account = BeshenceAccount(id: finalId);
    if(initAccountEvent) {
      var event = InitAccountEvent(accountId: finalId);
      await (await account.requireChain("main")).addEvent(event);
    }
    return account;
  }

  static Future<bool> removeAccount(BeshenceAccount account) async {
    if(!initialized) throw Exception("Beshence not initialized");

    final AccountV1? boxAccount = accountsV1Box.get(encodeKey(accountId: account.id));
    if (boxAccount == null) return false;

    await accountsV1Box.delete(boxAccount.id);
    return !accountsV1Box.containsKey(encodeKey(accountId: account.id));
  }

  static BeshenceAccount? get selectedAccount {
    if(!initialized) throw Exception("Beshence not initialized");
    final id = settingsBox.get('selectedAccountId');
    return id != null ? getAccount(id) : (accounts.isNotEmpty ? accounts.first : null);
  }

  static Future<void> setSelectedAccount(BeshenceAccount account) async {
    if(!initialized) throw Exception("Beshence not initialized");
    await settingsBox.put('selectedAccountId', account.id);
  }

  static Future<void> removeSelectedAccount() async {
    if(!initialized) throw Exception("Beshence not initialized");
    await settingsBox.delete('selectedAccountId');
  }
}