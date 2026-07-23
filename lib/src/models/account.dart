import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
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

  Future<BeshenceVault> addVault({required String bankId, required String vaultId, required int priority, bool addVaultEvent = true}) async {
    if(!initialized) throw Exception("Beshence not initialized");

    if(addVaultEvent) {
      AddVaultV1Event event = AddVaultV1Event(
          vaultId: vaultId,
          bankId: bankId,
          priority: priority,
          addedAt: DateTime.timestamp()
      );
      await (await requireChain("main")).addEvent(event);
    }

    if(!banksV1Box.containsKey(encodeKey(bankId: bankId))) {
      throw Exception("could not find this bank");
    }

    final VaultV1 newVault = VaultV1(
      id: vaultId,
      accountId: id,
      bankId: bankId,
      priority: priority
    );
    await vaultsV1Box.put(encodeKey(accountId: id, bankId: bankId, vaultId: vaultId), newVault);

    return BeshenceVault(id: vaultId, account: this, bank: BeshenceBank(id: bankId));
  }

  List<BeshenceVault> get vaults {
    if(!initialized) throw Exception("Beshence not initialized");

    final List<BeshenceVault> boxVaults = vaultsV1Box.values
        .where((vault) => vault.accountId == id)
        .map((vault) => BeshenceVault(id: vault.id, account: this, bank: BeshenceBank(id: vault.bankId)))
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id))
      ..sort((a, b) => b.priority.compareTo(a.priority));

    return boxVaults;
  }
}

