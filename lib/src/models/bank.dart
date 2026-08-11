import 'dart:convert';

import 'package:beshence_sdk_flutter/src/models/internal/bank.dart';

import '../../beshence_sdk_flutter.dart';

class BeshenceBank {
  final String id;

  BeshenceBank({required this.id});

  Future<List<BeshenceRemoteVault>> getVaults() async {
    try {
      var vaultsResponse = await internal.get(
          path: "/vaults",
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          }
      );
      var jsonResponse = jsonDecode(vaultsResponse.body);
      if (jsonResponse["err"] == "0") {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        List<BeshenceRemoteVault> vaults = List.from(
            jsonResponse["vaults"].map((item) =>
                BeshenceRemoteVault(id: item["id"], bank: this, name: item["name"])));

        return vaults;
      } else {
        throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createVault(String name) async {
    try {
      var vaultResponse = await internal.post(
          path: "/vault",
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'name': name
          })
      );
      var vaultJson = jsonDecode(vaultResponse.body);
      if (vaultJson["err"] == "0") {
        if (vaultJson is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }

        return vaultJson["id"]!;
      } else {
        throw StateError('Request failed with err ${vaultJson["err"]} and error ${vaultJson["errmsg"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> getAccountIdAttachedToVault(String vaultId) async {
    try {
      var chainsResponse = await internal.get(path: "/vault/$vaultId/chains");
      var chainsJson = jsonDecode(chainsResponse.body);
      if(chainsJson["err"] == "0") {
        List<dynamic> chains = List<String>.from((chainsJson["chains"] as List)
            .map((e) => e["name"]));
        if(!chains.contains("main")) return null;
      } else {
        throw StateError('Request failed with err ${chainsJson["err"]} and error ${chainsJson["errmsg"]}.');
      }

      var eventsResponse = await internal.get(path: "/vault/$vaultId/chain/main/events");
      var eventsJson = jsonDecode(eventsResponse.body);
      if(eventsJson["err"] == "0") {

      } else {
        throw StateError('Request failed with err ${eventsJson["err"]} and error ${eventsJson["errmsg"]}.');
      }

      String? accountId = "";

      for(Map<String, dynamic> event in eventsJson["events"]) {
        final String encodedPayload = event["payload"];
        final decodedPayload = jsonDecode(utf8.decode(base64.decode(encodedPayload)));
        final String eventName = decodedPayload["n"];
        final eventJson = decodedPayload["e"];

        if(eventName == "init_account") {
          accountId = eventJson["id"];
          break;
        }
      }

      return accountId;
    } catch(e) {
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BeshenceBank &&
        other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  BeshenceBankInternal get internal => BeshenceBankInternal(bank: this);
}

class BeshenceBankPKResponseV1 {
  final String rootPk;
  final String leafPk;
  final String leafSig;

  BeshenceBankPKResponseV1({
    required this.rootPk,
    required this.leafPk,
    required this.leafSig});
}

class BeshenceBankPingResponse {
  final String bankId;
  final String apiUrl;
  final List<String> registerMethods;
  final List<String> loginMethods;

  BeshenceBankPingResponse({
    required this.bankId,
    required this.apiUrl,
    required this.registerMethods,
    required this.loginMethods});
}

class BeshenceBankLoginResponse {
  final String refreshToken;
  final String accessToken;

  BeshenceBankLoginResponse({required this.refreshToken, required this.accessToken});
}