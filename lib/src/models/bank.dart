import 'dart:convert';

import 'package:http/http.dart' as http;

class BeshenceBank {
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
      if (jsonResponse["errcode"] == 0) {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        return BeshenceBankLoginResponse(refreshToken: jsonResponse["refresh_token"], accessToken: jsonResponse["access_token"]);
      } else {
        throw StateError('Request failed with errcode ${jsonResponse["errcode"]} and error ${jsonResponse["error"]}.');
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
      if (jsonResponse["errcode"] == 0) {
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        List<Map<String, String>> vaults = List<Map<String, String>>.from(
            jsonResponse["vaults"].map((item) => Map<String, String>.from(item))
        );
        return BeshenceBankVaultsResponse(vaults: vaults);
      } else {
        throw StateError('Request failed with errcode ${jsonResponse["errcode"]} and error ${jsonResponse["error"]}.');
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