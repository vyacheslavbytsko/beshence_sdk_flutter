import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:hive_ce/hive.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:uuid/uuid.dart';

import 'hive_objects/account_v1.dart';
import 'misc.dart';

class Beshence {
  static Future<List<BeshenceAccount>> getAccounts() async {
    await init();

    final Box<AccountV1> box = await getAccountsV1Box();
    List<AccountV1> boxAccounts = box.values.toList();

    return [for (var account in boxAccounts) BeshenceAccount(id: account.id)];
  }

  static Future<BeshenceAccount?> getAccount(String id) async {
    await init();

    final Box<AccountV1> box = await getAccountsV1Box();
    final AccountV1? boxAccount = box.get(id);
    if (boxAccount == null) return null;

    return BeshenceAccount(id: boxAccount.id);
  }

  static Future<BeshenceAccount> createAccount() async {
    await init();

    final Box<AccountV1> box = await getAccountsV1Box();

    String id;
    do {
      id = Uuid().v4();
    } while (box.containsKey(id));

    final account = AccountV1(id: id);
    await box.put(id, account);

    if (!box.containsKey(id)) {
      throw StateError('Couldn\'t save account');
    }

    return BeshenceAccount(id: id);
  }

  static Future<bool> removeAccount(BeshenceAccount account) async {
    await init();

    final Box<AccountV1> box = await getAccountsV1Box();
    final AccountV1? boxAccount = box.get(account.id);
    if (boxAccount == null) return false;

    await box.delete(boxAccount.id);
    return !box.containsKey(account.id);
  }
}