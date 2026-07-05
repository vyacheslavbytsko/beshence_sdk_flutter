import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/chain_v1.dart';

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

    if (chainsV1Box.containsKey(encodeKey(accountId: id, chainName: name))) {
      throw Exception('Chain with name $name already exists for this account');
    }

    // TODO: check name

    final ChainV1 newChain = ChainV1(
      name: name,
      accountId: id,
      lastEventId: null
    );
    await chainsV1Box.put(encodeKey(accountId: id, chainName: name), newChain);
    return BeshenceChain(name: newChain.name, account: this);
  }

  BeshenceChain? getChain(String name) {
    if(!initialized) throw Exception("Beshence not initialized");

    final ChainV1? chainV1 = chainsV1Box.get(encodeKey(accountId: id, chainName: name));
    return chainV1 == null ? null : BeshenceChain(
        name: chainV1.name,
        account: this);
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

  Future<void> addVault({required String address, required String vaultId, required String bankId, required int priority, required String refreshToken, required String accessToken}) async {
    if(!initialized) throw Exception("Beshence not initialized");

    AddVaultV1Event event = AddVaultV1Event(
        address: address,
        vaultId: vaultId,
        bankId: bankId,
        priority: priority,
        addedAt: DateTime.timestamp()
    );
    await (await requireChain("main")).addEvent(event);

    final VaultV1 newVault = VaultV1(
      id: vaultId,
      accountId: id,
      bankId: bankId,
      apiUrls: [address],
      refreshToken: refreshToken,
      accessToken: accessToken
    );
    await vaultsV1Box.put(encodeKey(accountId: id, vaultId: vaultId), newVault);
  }

  List<BeshenceVault> get vaults {
    if(!initialized) throw Exception("Beshence not initialized");

    final List<BeshenceVault> boxVaults = vaultsV1Box.values
        .where((vault) => vault.accountId == id)
        .map((vault) => BeshenceVault(id: vault.id, account: this))
        .toList();

    return boxVaults;
  }
}

