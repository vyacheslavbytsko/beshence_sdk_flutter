import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/events/init_account.dart';
import 'package:beshence_sdk_flutter/src/events/issue_token_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

import '../hive_registrar.g.dart';
import 'events/set_vaults_priorities_v1.dart';
import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';
import 'misc.dart';
import 'models/internal/bank.dart';

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
    eventsRegistry.register<SetVaultsPrioritiesV1Event>(SetVaultsPrioritiesV1EventSpec());
    eventsRegistry.register<IssueTokenV1Event>(IssueTokenV1EventSpec());

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

  static Future<BeshenceAccount> createAccount({String? id, String? oauthTokenId, bool initAccountEvent = true}) async {
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
    final accountV1 = AccountV1(id: finalId, oauthTokenId: oauthTokenId);
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

  static Future<BeshenceBankPKResponseV1> getBankPublicKeysV1({required String bankId}) async {
    try {
      var gatewayUrl = Uri.parse("https://gateway.beshence.com/api/bank/$bankId/pk");
      var gatewayResponse = await http.get(gatewayUrl);

      var gatewayJson = jsonDecode(gatewayResponse.body);

      if (gatewayJson is! Map<String, dynamic>) {
        throw StateError('Invalid response format');
      }

      if (gatewayJson["err"] != "0") {
        throw StateError("Error ${gatewayJson["err"]}");
      }

      return BeshenceBankPKResponseV1(
          rootPk: gatewayJson["root"]["pk"],
          leafPk: gatewayJson["leaf"]["pk"],
          leafSig: gatewayJson["leaf"]["sig"]);
    } catch (e) {
      rethrow;
    }
  }

  static Future<BeshenceBankPingResponse> pingBank({required String bankId}) async {
    final bankApiUrls = await getBankApiUrls(bankId: bankId);

    for (final bankApiUrl in bankApiUrls) {
      try {
        final response = await _bankRequest(
          bankId: bankId,
          apiUrl: bankApiUrl,
          method: "GET",
          path: "/ping",
        );

        final bankJson = jsonDecode(response.body);

        if (bankJson is! Map<String, dynamic>) {
          continue;
        }

        if (bankJson["ping"] != "beshence-bank-pong!") {
          continue;
        }

        return BeshenceBankPingResponse(
          bankId: bankJson["id"],
          apiUrl: bankApiUrl,
          registerMethods:
          List<String>.from(
            bankJson["auth"]["register"]["methods"],
          ),
          loginMethods:
          List<String>.from(
            bankJson["auth"]["login"]["methods"],
          ),
        );
      } catch (e) {
        continue;
      }
    }

    throw StateError("cant access this bank",);
  }

  static Future<void> loginToBank({
    required String bankId,
    required String username,
    required String password,
  }) async {
    final bankApiUrl = (await pingBank(bankId: bankId)).apiUrl;

    final response = await _bankRequest(
      bankId: bankId,
      apiUrl: bankApiUrl,
      method: "POST",
      path: "/auth/login",
      headers: {
        "Content-Type":
        "application/json; charset=UTF-8",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    final loginJson =
    jsonDecode(response.body);

    if(loginJson["err"] != "0") {
      throw StateError(
        'Request failed with err '
            '${loginJson["err"]} and error '
            '${loginJson["errmsg"]}.',
      );
    }

    if(loginJson is! Map<String,dynamic>) {
      throw StateError(
        "Invalid response format",
      );
    }

    if(!banksV1Box.containsKey(encodeKey(bankId: bankId))) {
      final bank = BankV1(
        id: bankId,
        accessToken: loginJson["access_token"],
        refreshToken: loginJson["refresh_token"],
      );

      await banksV1Box.put(
        encodeKey(bankId: bankId),
        bank,
      );
    }
  }

  static Future<void> registerInBank({
    required String bankId,
    required String username,
    required String password,
  }) async {
    final bankApiUrl = (await pingBank(bankId: bankId)).apiUrl;

    final response = await _bankRequest(
      bankId: bankId,
      apiUrl: bankApiUrl,
      method: "POST",
      path: "/auth/register",
      headers: {
        "Content-Type":
        "application/json; charset=UTF-8",
      },
      body: jsonEncode({
        "username": username,
        "password": password,
      }),
    );

    final json = jsonDecode(response.body);

    if(json["err"] != "0") {
      throw StateError(
        'Request failed with err '
            '${json["err"]} and error '
            '${json["errmsg"]}.',
      );
    }

    if(json is! Map<String,dynamic>) {
      throw StateError("Invalid response format",);
    }

    if(!banksV1Box.containsKey(encodeKey(bankId: bankId))) {
      final bank = BankV1(
        id: bankId,
        accessToken: json["access_token"],
        refreshToken: json["refresh_token"],
      );

      await banksV1Box.put(encodeKey(bankId: bankId), bank);
    }
  }

  static Future<http.Response> _bankRequest({
    required String bankId,
    required String apiUrl,
    required String method,
    required String path,
    Map<String, String>? headers,
    String? body,
  }) async {
    if (apiUrl.startsWith("gateway://")) {
      final connection = await BBIPeerConnection.getFor(bankId);

      return connection.request(
        method: method,
        path: path,
        headers: headers,
        body: body,
      );
    }

    final uri = Uri.parse("$apiUrl$path");

    switch(method) {
      case "GET":
        return http.get(uri, headers: headers);
      case "POST":
        return http.post(uri, headers: headers, body: body);
      default:
        throw UnsupportedError("Unsupported method $method",);
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