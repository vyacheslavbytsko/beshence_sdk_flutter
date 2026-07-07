import 'dart:convert';

import '../../beshence_sdk_flutter.dart';

class BeshenceRemoteChain {
  BeshenceVault vault;
  BeshenceChain chain;

  BeshenceRemoteChain({required this.vault, required this.chain});

  Future<String?> get remoteLastEventId async {
    List<String> onlineBankApiUrls = await vault.bank.onlineApiUrls;
    if(onlineBankApiUrls.isEmpty) throw Exception("offline");

    String onlineBankApiUrl = onlineBankApiUrls.first;

    var url = Uri.parse('$onlineBankApiUrl/api/vault/${vault.id}/chain/${chain.name}/event/last');
    var response = await vault.bank.authenticatedHttpGet(url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var jsonResponse = jsonDecode(response.body);

    String? remoteLastEventId;

    if(jsonResponse["err"] == "0") {
      remoteLastEventId = jsonResponse["event"]["id"];
    } else if(jsonResponse["err"] == "NO_LAST_EVENT") {
      remoteLastEventId = null;
    } else {
      throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
    }

    return remoteLastEventId;
  }
}