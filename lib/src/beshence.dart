import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../hive_registrar.g.dart';
import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';
import 'misc.dart';

class Beshence {
  static Future<void> init() async {
    if (initialized) return;

    await Hive.initFlutter();
    Hive.registerAdapters();

    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    var appId = packageInfo.packageName;

    String prefix = "beshence_$appId";
    settingsBox = await Hive.openBox('${prefix}_settings');
    accountsV1Box = await Hive.openBox<AccountV1>('${prefix}_accounts_v1');
    vaultsV1Box = await Hive.openBox<VaultV1>('${prefix}_vaults_v1');
    chainsV1Box = await Hive.openBox<ChainV1>('${prefix}_chains_v1');
    eventsV1Box = await Hive.openBox<EventV1>('${prefix}_events_v1');

    initialized = true;
  }

  static List<BeshenceAccount> get accounts {
    if(!initialized) throw Exception("Beshence not initialized");

    List<AccountV1> boxAccounts = accountsV1Box.values.toList();

    return [for (var account in boxAccounts) BeshenceAccount(id: account.id)];
  }

  static BeshenceAccount? getAccount(String id) {
    if(!initialized) throw Exception("Beshence not initialized");

    final AccountV1? boxAccount = accountsV1Box.get(id);
    if (boxAccount == null) return null;

    return BeshenceAccount(id: boxAccount.id);
  }

  static Future<BeshenceAccount> createAccount() async {
    if(!initialized) throw Exception("Beshence not initialized");

    String id;
    do {
      id = Uuid().v4();
    } while (accountsV1Box.containsKey(id));

    final account = AccountV1(id: id);
    await accountsV1Box.put(id, account);

    if (!accountsV1Box.containsKey(id)) {
      throw StateError('Couldn\'t save account');
    }

    return BeshenceAccount(id: id);
  }

  static Future<bool> removeAccount(BeshenceAccount account) async {
    if(!initialized) throw Exception("Beshence not initialized");

    final AccountV1? boxAccount = accountsV1Box.get(account.id);
    if (boxAccount == null) return false;

    await accountsV1Box.delete(boxAccount.id);
    return !accountsV1Box.containsKey(account.id);
  }

  static BeshenceAccount? get selectedAccount {
    if(!initialized) throw Exception("Beshence not initialized");
    final id = settingsBox.get('selectedAccountId');
    return id != null ? getAccount(id) : (accounts.isNotEmpty ? accounts.first : null);
  }

  static void setSelectedAccount(BeshenceAccount account) async {
    if(!initialized) throw Exception("Beshence not initialized");
    await settingsBox.put('selectedAccountId', account.id);
  }

  static Future<void> removeSelectedAccount() async {
    if(!initialized) throw Exception("Beshence not initialized");
    await settingsBox.delete('selectedAccountId');
  }

  static Future<PingBankResponse> pingBank({required String address}) async {
    try {
      var url = Uri.parse('$address/.well-known/beshence/bank');
      var response = await http.get(url);
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        if (jsonResponse['ping'] == 'beshence-pong!') {
          var authMethods = jsonResponse["auth"]["methods"];
          return PingBankResponse(
              authMethods: List<String>.from(authMethods)
          );
        } else {
          throw StateError('Unexpected ping response');
        }
      } else {
        throw StateError('Request failed with status: ${response.statusCode}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<LoginBankResponse> loginBank({required String address, required String username, required String password}) async {
    try {
      var url = Uri.parse('$address/api/auth/login');
      var response = await http.post(url,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'username': username,
            'password': password
          })
      );
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["errcode"] == 0) {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        return LoginBankResponse(refreshToken: jsonResponse["refresh_token"], accessToken: jsonResponse["access_token"]);
      } else {
        throw StateError('Request failed with errcode ${jsonResponse["errcode"]} and error ${jsonResponse["error"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<VaultsResponse> getVaultsOfBank({required String address, required String accessToken}) async {
    try {
      var url = Uri.parse('$address/api/vault');
      var response = await http.get(url,
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
          }
      );
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["errcode"] == 0) {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        List<Map<String, String>> vaults = List<Map<String, String>>.from(
            jsonResponse["vaults"].map((item) => Map<String, String>.from(item))
        );
        return VaultsResponse(vaults: vaults);
      } else {
        throw StateError('Request failed with errcode ${jsonResponse["errcode"]} and error ${jsonResponse["error"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }
}