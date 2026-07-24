import 'dart:convert';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/misc.dart';

class BeshenceVault {
  final String id;
  final BeshenceAccount account;
  final BeshenceBank bank;

  BeshenceVault({required this.id, required this.account, required this.bank});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BeshenceVault &&
        other.id == id &&
        other.account == account &&
        other.bank == bank;
  }

  @override
  int get hashCode => Object.hash(id, account, bank);

  int get priority => vaultsV1Box.get(encodeKey(accountId: account.id, bankId: bank.id, vaultId: id))!.priority;

  BeshenceVaultChain chain(BeshenceChain chain) => BeshenceVaultChain(vault: this, chain: chain);

  Future<List<BeshenceVaultChain>> get chains async {
    String bankApiUrl = (await Beshence.pingBank(bankId: bank.id)).apiUrl;

    var chainsUrl = Uri.parse("$bankApiUrl/vault/$id/chains");
    var chainsResponse = await bank.authenticatedHttpGet(chainsUrl);
    var chainsJson = jsonDecode(chainsResponse.body);
    if(chainsJson["err"] == "0") {
      List<BeshenceVaultChain> chains = List<BeshenceVaultChain>.from((chainsJson["chains"] as List)
          .map((e) => chain(BeshenceChain(name: e["name"], account: account))));
      return chains;
    } else {
      throw StateError('Request failed with err ${chainsJson["err"]} and error ${chainsJson["errmsg"]}.');
    }
  }
}