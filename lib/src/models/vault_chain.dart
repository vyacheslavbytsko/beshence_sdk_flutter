import 'dart:convert';

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/event_v1.dart';
import '../misc.dart';

class BeshenceVaultChain {
  BeshenceChain chain;
  BeshenceVault vault;

  BeshenceVaultChain({required this.chain, required this.vault});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BeshenceVaultChain &&
        other.chain == chain &&
        other.vault == vault;
  }

  @override
  int get hashCode => Object.hash(chain, vault);

  Future<String?> get remoteLastEventId async {
    String? onlineBankApiUrl = await vault.bank.onlineApiUrl;
    if(onlineBankApiUrl == null) throw Exception("offline");

    List<BeshenceVaultChain> chains = await vault.chains;
    if(!chains.contains(BeshenceVaultChain(chain: chain, vault: vault))) {

    }

    var url = Uri.parse('$onlineBankApiUrl/vault/${vault.id}/chain/${chain.name}/event/last');
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

  Future<void> pushEvent(BeshenceEvent event) async {
    String? onlineBankApiUrl = await vault.bank.onlineApiUrl;
    if(onlineBankApiUrl == null) throw Exception("offline");

    final mapper = eventsRegistry.specForType(event.runtimeType);
    Map<String, dynamic> json = {
      "n": mapper.name,
      "e": mapper.toJson(event)
    };
    var payload = base64.encode(utf8.encode(jsonEncode(json)));

    var url = Uri.parse('$onlineBankApiUrl/vault/${vault.id}/chain/${chain.name}/event');
    var response = await vault.bank.authenticatedHttpPost(url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        "id": event.id,
        "parent_id": event.parent?.id,
        "payload": payload
      }),
    );
    var jsonResponse = jsonDecode(response.body);

    if(jsonResponse["err"] != "0") {
      throw StateError('Request failed with err ${jsonResponse["err"]} and error ${jsonResponse["errmsg"]}.');
    }

    String eventV1Key = encodeKey(accountId: chain.account.id, chainName: chain.name, eventId: event.id);
    EventV1 eventV1 = eventsV1Box.get(eventV1Key)!;
    EventV1 newEventV1 = EventV1(
      id: eventV1.id,
      name: eventV1.name,
      chainName: eventV1.chainName,
      accountId: eventV1.accountId,
      parentId: event.parent?.id,
      payload: eventV1.payload,
      applied: eventV1.applied,
      synced: true
    );
    await eventsV1Box.put(eventV1Key, newEventV1);
  }
}

class BeshenceRemoteVault {
  final String id;
  final BeshenceBank bank;
  final String name;

  BeshenceRemoteVault({required this.id, required this.bank, required this.name});
}