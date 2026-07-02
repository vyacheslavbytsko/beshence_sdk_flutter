import 'dart:convert' as convert;

import 'package:hive_ce/hive.dart';
import 'package:http/http.dart' as http;

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class BeshenceAccount {
  final String id;

  BeshenceAccount({required this.id});

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
        .map((vault) => BeshenceVault(id: vault.id))
        .toList();

    return boxVaults;
  }*/
}

