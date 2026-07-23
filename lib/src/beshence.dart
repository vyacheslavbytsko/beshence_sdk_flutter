import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/events/init_account.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:http/http.dart' as http;
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
  static Future<void> init({BeshenceEventRegistry? registry}) async {
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

    eventsRegistry = registry ?? BeshenceEventRegistry();
    eventsRegistry.register<InitAccountEvent>(InitAccountEventSpec());
    eventsRegistry.register<AddVaultV1Event>(AddVaultV1EventSpec());
    eventsRegistry.register<ChangeVaultsPrioritiesV1Event>(ChangeVaultsPrioritiesV1EventSpec());

    initialized = true;
  }

  static List<BeshenceAccount> get accounts {
    if(!initialized) throw Exception("Beshence not initialized");

    List<AccountV1> accountsV1 = accountsV1Box.values.toList();

    return [for (var accountV1 in accountsV1) BeshenceAccount(id: accountV1.id)];
  }

  static BeshenceAccount? getAccount(String id) {
    if(!initialized) throw Exception("Beshence not initialized");

    final AccountV1? accountV1 = accountsV1Box.get(encodeKey(accountId: id));
    if (accountV1 == null) return null;

    return BeshenceAccount(id: accountV1.id);
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
    final accountV1 = AccountV1(id: finalId);
    await accountsV1Box.put(encodeKey(accountId: finalId), accountV1);

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

    final AccountV1? accountV1 = accountsV1Box.get(encodeKey(accountId: account.id));
    if (accountV1 == null) return false;

    await accountsV1Box.delete(accountV1.id);
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

  static Future<List<String>> getBankApiUrls({required String bankId}) async {
    try {
      var gatewayUrl = Uri.parse("https://gateway.beshence.com/api/bank/$bankId/urls");
      var gatewayResponse = await http.get(gatewayUrl);

      var gatewayJson = jsonDecode(gatewayResponse.body);

      if (gatewayJson is! Map<String, dynamic>) {
        throw StateError('Invalid response format');
      }

      if (gatewayJson["err"] != "0") {
        throw StateError("Error ${gatewayJson["err"]}");
      }

      return List<String>.from(gatewayJson["urls"]);
    } catch (e) {
      rethrow;
    }
  }

  static Future<BeshenceBankPingResponse> pingBank({required String bankId}) async {
      List<String> bankApiUrls = await getBankApiUrls(bankId: bankId);

      for (String bankApiUrl in bankApiUrls) {
        try {
          var bankUri = Uri.parse("$bankApiUrl/ping");
          var bankResponse = await http.get(bankUri);

          var bankJson = jsonDecode(bankResponse.body);

          if (bankJson is! Map<String, dynamic>) {
            throw StateError('Invalid response format');
          }

          if (bankJson['ping'] == 'beshence-bank-pong!') {
            return BeshenceBankPingResponse(
                bankId: bankJson["id"],
                apiUrl: bankApiUrl,
                registerMethods: List<String>.from(bankJson["auth"]["register"]["methods"]),
                loginMethods: List<String>.from(bankJson["auth"]["login"]["methods"])
            );
          } else {
            throw StateError('Unexpected ping response');
          }
        } catch (e) {}
      }

      throw StateError("cant access this bank");

  }

  static Future<void> loginToBank({required String bankId, required String username, required String password}) async {
    try {
      String bankApiUrl = (await pingBank(bankId: bankId)).apiUrl;

      var loginUrl = Uri.parse('$bankApiUrl/auth/login');
      var loginResponse = await http.post(loginUrl,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'username': username,
            'password': password
          })
      );
      var loginJson = jsonDecode(loginResponse.body);
      if (loginJson["err"] == "0") {
        if (loginJson is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }

        if(!banksV1Box.containsKey(encodeKey(bankId: bankId))) {
          final BankV1 newBank = BankV1(
              id: bankId,
              apiUrls: await getBankApiUrls(bankId: bankId),
              accessToken: loginJson["access_token"],
              refreshToken: loginJson["refresh_token"]
          );
          await banksV1Box.put(encodeKey(bankId: bankId), newBank);
        }
      } else {
        throw StateError('Request failed with err ${loginJson["err"]} and error ${loginJson["errmsg"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  // TODO: should be tied to BeshenceBank
  static Future<BeshenceBankVaultsResponse> getVaultsOfBank({required String bankId}) async {
    try {
      String bankApiUrl = (await pingBank(bankId: bankId)).apiUrl;

      var vaultsUrl = Uri.parse('$bankApiUrl/vault');
      var vaultsResponse = await getBank(bankId)!.authenticatedHttpGet(vaultsUrl,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          }
      );
      var jsonResponse = jsonDecode(vaultsResponse.body);
      if (jsonResponse["err"] == "0") {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        List<Map<String, String>> vaults = List<Map<String, String>>.from(
            jsonResponse["vaults"].map((item) => Map<String, String>.from(item))
        );
        return BeshenceBankVaultsResponse(vaults: vaults);
      } else {
        throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  static List<BeshenceBank> get banks {
    if(!initialized) throw Exception("Beshence not initialized");

    List<BankV1> banksV1 = banksV1Box.values.toList();

    return [for (var bankV1 in banksV1) BeshenceBank(id: bankV1.id)];
  }

  static BeshenceBank? getBank(String id) {
    if(!initialized) throw Exception("Beshence not initialized");

    final BankV1? bankV1 = banksV1Box.get(encodeKey(bankId: id));
    if (bankV1 == null) return null;

    return BeshenceBank(id: id);
  }
}