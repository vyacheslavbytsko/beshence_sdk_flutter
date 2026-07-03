import 'dart:convert' as convert;

import 'package:beshence_sdk_flutter/src/hive_objects/chain_v1.dart';
import 'package:beshence_sdk_flutter/src/models/chain.dart';
import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class BeshenceAccount {
  final String id;

  BeshenceAccount({required this.id});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BeshenceAccount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  Future<BeshenceChain> createChain(String name) async {
    if(!initialized) throw Exception("Beshence not initialized");

    if (chainsV1Box.containsKey(name)) {
      throw Exception('Chain with name $name already exists for this account');
    }

    // TODO: check name

    final ChainV1 newChain = ChainV1(
      name: name,
      accountId: id,
      lastEventId: null
    );
    await chainsV1Box.put("${id}_$name", newChain);
    return BeshenceChain(name: newChain.name, account: this);
  }

  BeshenceChain? getChain(String name) {
    if(!initialized) throw Exception("Beshence not initialized");

    final ChainV1? chainV1 = chainsV1Box.get("${id}_$name");
    return chainV1 != null ? BeshenceChain(name: chainV1.name, account: this) : null;
  }

  Future<BeshenceChain> requireChain(String name) async {
    if(!initialized) throw Exception("Beshence not initialized");
    final BeshenceChain? chain = getChain(name);
    return chain ?? await createChain(name);
  }

  List<BeshenceChain> get chains {
    if(!initialized) throw Exception("Beshence not initialized");

    final List<BeshenceChain> boxChains = chainsV1Box.values
        .where((chain) => chain.accountId == id)
        .map((chain) => BeshenceChain(name: chain.name, account: this))
        .toList();

    return boxChains;
  }

  /*Future<void> addVault({required String address, BeshenceVaultLoginPayload? loginPayload}) async {
    var url = Uri.parse('$address/.well-known/beshence/bank');

    try {
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = convert.jsonDecode(response.body);
        if (jsonResponse is! Map<String, dynamic>) {
          throw StateError('Invalid response format');
        }
        if (jsonResponse['ping'] == 'beshence-pong!') {
          // this is an actual beshence bank
          print('YAAS');
          // TODO add vault using $accountId_$vaultId
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

  Future<List<BeshenceVault>> get vaults async {
    await Beshence.init();

    final Box<VaultV1> box = await getVaultsV1Box();
    final List<BeshenceVault> boxVaults = box.values
        .where((vault) => vault.accountId == id)
        .map((vault) => BeshenceVault(id: vault.id, account: this))
        .toList();

    return boxVaults;
  }*/
}

