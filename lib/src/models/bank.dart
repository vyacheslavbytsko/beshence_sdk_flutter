import 'dart:convert';

import 'package:beshence_sdk_flutter/src/misc.dart';
import 'package:http/http.dart' as http;

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/bank_v1.dart';

class BeshenceBank {
  final String id;

  BeshenceBank({required this.id});

  Future<String?> get onlineApiUrl async {
    try {
      return (await Beshence.pingBank(bankId: id)).apiUrl;
    } catch(e) {
      return null;
    }
  }

  Future<List<BeshenceRemoteVault>> getVaults() async {
    try {
      String bankApiUrl = (await Beshence.pingBank(bankId: id)).apiUrl;

      var vaultsUrl = Uri.parse('$bankApiUrl/vault');
      var vaultsResponse = await authenticatedHttpGet(vaultsUrl,
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

  Future<List<String>> createVault(String name) async {
    try {
      String bankApiUrl = (await Beshence.pingBank(bankId: id)).apiUrl;

      var vaultUrl = Uri.parse('$bankApiUrl/vault');
      var vaultResponse = await authenticatedHttpPost(vaultUrl,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({
            'name': name
          })
      );
      var vaultJson = jsonDecode(vaultResponse.body);
      print(vaultJson);
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

  Future<http.Response> authenticatedHttpGet(Uri url, {Map<String, String>? headers}) async {
    BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: id))!;
    String accessToken = bankV1.accessToken!; String refreshToken = bankV1.refreshToken!;

    Map<String, String> newHeaders = {};

    if(headers != null) newHeaders.addAll(headers);
    newHeaders["Authorization"] = "Bearer $accessToken";

    try {
      var response = await http.get(url, headers: newHeaders);
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["err"] != "UNAUTHORIZED") return response;

      try {
        var authUrl = Uri.parse('${url.origin}/api/auth/refresh');
        var response = await http.get(authUrl,
            headers: <String, String>{
              'Authorization': 'Bearer $refreshToken',
              'Content-Type': 'application/json; charset=UTF-8',
            }
        );
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse["err"] == "0") {
          if (jsonResponse is! Map<String, dynamic>) {
            throw StateError('Invalid response format');
          }
          bankV1.accessToken = jsonResponse["access_token"];
          bankV1.refreshToken = jsonResponse["refresh_token"];
          await banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
          return authenticatedHttpGet(url, headers: headers);
        } else {
          throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> authenticatedHttpPost(Uri url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: id))!;
    String accessToken = bankV1.accessToken!; String refreshToken = bankV1.refreshToken!;

    Map<String, String> newHeaders = {};

    if(headers != null) newHeaders.addAll(headers);
    newHeaders["Authorization"] = "Bearer $accessToken";

    try {
      var response = await http.post(url, headers: newHeaders, body: body, encoding: encoding);
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["err"] != "UNAUTHORIZED") return response;

      try {
        var authUrl = Uri.parse('${url.origin}/api/auth/refresh');
        var response = await http.get(authUrl,
            headers: <String, String>{
              'Authorization': 'Bearer $refreshToken',
              'Content-Type': 'application/json; charset=UTF-8',
            }
        );
        var jsonResponse = jsonDecode(response.body);
        if (jsonResponse["err"] == "0") {
          if (jsonResponse is! Map<String, dynamic>) {
            throw StateError('Invalid response format');
          }
          bankV1.accessToken = jsonResponse["access_token"];
          bankV1.refreshToken = jsonResponse["refresh_token"];
          await banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
          return authenticatedHttpGet(url, headers: headers);
        } else {
          throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
        }
      } catch (e) {
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }
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