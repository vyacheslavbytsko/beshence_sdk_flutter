import 'dart:convert';

import 'package:beshence_sdk_flutter/src/misc.dart';
import 'package:http/http.dart' as http;

import '../hive_objects/bank_v1.dart';

class BeshenceBank {
  final String id;

  BeshenceBank({required this.id});

  static Future<BeshenceBankPingResponse> ping({required String address}) async {
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
          return BeshenceBankPingResponse(
              bankId: jsonResponse["id"],
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

  static Future<BeshenceBankLoginResponse> login({required String address, required String username, required String password}) async {
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
      if (jsonResponse["err"] == "0") {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        return BeshenceBankLoginResponse(refreshToken: jsonResponse["refresh_token"], accessToken: jsonResponse["access_token"]);
      } else {
        throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<BeshenceBankVaultsResponse> getVaults({required String address, required String accessToken}) async {
    try {
      var url = Uri.parse('$address/api/vault');
      var response = await http.get(url,
          headers: <String, String>{
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json; charset=UTF-8',
          }
      );
      var jsonResponse = jsonDecode(response.body);
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

  Future<List<String>> get onlineApiUrls async {
    BankV1? bankV1 = banksV1Box.get(encodeKey(bankId: id));
    List<String> onlineUrls = [];
    for(String bankApiUrl in bankV1!.apiUrls!) {
      BeshenceBankPingResponse response = await BeshenceBank.ping(address: bankApiUrl);
      if(response.bankId == id) {
        onlineUrls.add(bankApiUrl);
      }
    }
    return onlineUrls;
  }

  Future<http.Response> authenticatedHttpGet(Uri url, {Map<String, String>? headers}) async {
    BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: id))!;
    String accessToken = bankV1.accessToken; String refreshToken = bankV1.refreshToken;

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
          banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
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
  final List<String> authMethods;

  BeshenceBankPingResponse({required this.bankId, required this.authMethods});
}

class BeshenceBankLoginResponse {
  final String refreshToken;
  final String accessToken;

  BeshenceBankLoginResponse({required this.refreshToken, required this.accessToken});
}

class BeshenceBankVaultsResponse {
  final List<Map<String, String>> vaults;

  BeshenceBankVaultsResponse({required this.vaults});
}