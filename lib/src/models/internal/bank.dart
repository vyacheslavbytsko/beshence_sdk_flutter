import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../beshence_sdk_flutter.dart';
import '../../hive_objects/account_v1.dart';
import '../../hive_objects/bank_v1.dart';
import '../../misc.dart';

class BeshenceBankInternal {
  BeshenceBank bank;

  static final Map<BeshenceBank, String?> onlineApiUrls = {};
  String? get onlineApiUrl => onlineApiUrls[bank];
  set onlineApiUrl(String? value) => onlineApiUrls[bank] = value;

  BeshenceBankInternal({required this.bank});

  Future<http.Response> get({
    BeshenceVault? vault,
    required String path,
    Map<String, String>? headers,
    int? tries
  }) async {
    if((tries ?? 0) >= 3) {
      throw StateError('Too many attempts.');
    }

    try {
      if(onlineApiUrl == null) {
        await updateOnlineApiUrl();
      }

      var (newHeaders, oauth, refreshToken) = tokenize(vault: vault, headers: headers);

      var response = await http.get(Uri.parse(onlineApiUrl!+path), headers: newHeaders);

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["err"] != "UNAUTHORIZED") return response;

      if(!oauth) {
        try {
          var authUrl = Uri.parse('$onlineApiUrl/auth/refresh');
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
            BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: bank.id))!;
            bankV1.accessToken = jsonResponse["access_token"];
            bankV1.refreshToken = jsonResponse["refresh_token"];
            await banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
            return get(
                vault: vault,
                path: path,
                headers: headers,
                tries: (tries ?? 0)+1
            );
          } else {
            throw StateError(
                'Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
          }
        } on SocketException catch (e) {
          print('No Internet Connection / Failed Host Lookup: $e');
          updateOnlineApiUrl();
          return get(
              vault: vault,
              path: path,
              headers: headers,
              tries: (tries ?? 0)+1
          );
        } on http.ClientException catch (e) {
          print('HTTP Client Exception: $e');
          updateOnlineApiUrl();
          return get(
              vault: vault,
              path: path,
              headers: headers,
              tries: (tries ?? 0)+1
          );
        } catch (e) {
          rethrow;
        }
      } else {
        throw StateError(
            'Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
      }
    } on SocketException catch (e) {
      print('No Internet Connection / Failed Host Lookup: $e');
      updateOnlineApiUrl();
      return get(
          vault: vault,
          path: path,
          headers: headers,
          tries: (tries ?? 0)+1
      );
    } on http.ClientException catch (e) {
      print('HTTP Client Exception: $e');
      updateOnlineApiUrl();
      return get(
          vault: vault,
          path: path,
          headers: headers,
          tries: (tries ?? 0)+1
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<http.Response> post({
    BeshenceVault? vault,
    required String path,
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    int? tries
  }) async {
    if((tries ?? 0) >= 3) {
      throw StateError('Too many attempts.');
    }

    try {
      if(onlineApiUrl == null) {
        await updateOnlineApiUrl();
      }

      var (newHeaders, oauth, refreshToken) = tokenize(vault: vault, headers: headers);

      var response = await http.post(Uri.parse(onlineApiUrl!+path),
          headers: newHeaders, body: body, encoding: encoding);

      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["err"] != "UNAUTHORIZED") return response;

      if(!oauth) {
        try {
          var authUrl = Uri.parse('${await onlineApiUrl}/auth/refresh');
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
            BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: bank.id))!;
            bankV1.accessToken = jsonResponse["access_token"];
            bankV1.refreshToken = jsonResponse["refresh_token"];
            await banksV1Box.put(encodeKey(bankId: bankV1.id), bankV1);
            return post(
                vault: vault,
                path: path,
                headers: headers,
                body: body,
                encoding: encoding,
                tries: (tries ?? 0)+1
            );
          } else {
            throw StateError(
                'Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
          }
        } on SocketException catch (e) {
          print('No Internet Connection / Failed Host Lookup: $e');
          updateOnlineApiUrl();
          return post(
              vault: vault,
              path: path,
              headers: headers,
              body: body,
              encoding: encoding,
              tries: (tries ?? 0)+1
          );
        } on http.ClientException catch (e) {
          print('HTTP Client Exception: $e');
          updateOnlineApiUrl();
          return post(
              vault: vault,
              path: path,
              headers: headers,
              body: body,
              encoding: encoding,
              tries: (tries ?? 0)+1
          );
        } catch (e) {
          rethrow;
        }
      } else {
        throw StateError(
            'Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
      }
    } on SocketException catch (e) {
      print('No Internet Connection / Failed Host Lookup: $e');
      updateOnlineApiUrl();
      return post(
          vault: vault,
          path: path,
          headers: headers,
          body: body,
          encoding: encoding,
          tries: (tries ?? 0)+1
      );
    } on http.ClientException catch (e) {
      print('HTTP Client Exception: $e');
      updateOnlineApiUrl();
      return post(
          vault: vault,
          path: path,
          headers: headers,
          body: body,
          encoding: encoding,
          tries: (tries ?? 0)+1
      );
    } catch (e) {
      rethrow;
    }
  }

  (Map<String, String>, bool, String?) tokenize({BeshenceVault? vault, Map<String, String>? headers}) {
    BankV1 bankV1 = banksV1Box.get(encodeKey(bankId: bank.id))!;
    AccountV1? accountV1 = accountsV1Box.get(encodeKey(accountId: vault?.account.id));

    String? accessToken = bankV1.accessToken;
    String? refreshToken = bankV1.refreshToken;
    String? oauthTokenId = accountV1?.oauthTokenId;

    bool oauth = false;

    if (oauthTokenId != null && vault != null) {
      oauth = true;
    } else if(accessToken == null || refreshToken == null) {
      throw Exception("no authentication tokens");
    }

    Map<String, String> newHeaders = {};

    if(headers != null) newHeaders.addAll(headers);
    newHeaders["Authorization"] = "Bearer ${oauth ? "oauthv1_${vault!.id}_$oauthTokenId" : accessToken}";

    return (newHeaders, oauth, refreshToken);
  }

  Future<void> updateOnlineApiUrl() async {
    try {
      onlineApiUrl = (await Beshence.pingBank(bankId: bank.id)).apiUrl;
    } catch(e) {
      onlineApiUrl = null;
    }
  }
}