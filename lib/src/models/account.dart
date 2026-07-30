import 'package:beshence_sdk_flutter/src/events/add_vault_v1.dart';
import 'package:beshence_sdk_flutter/src/events/issue_token_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/chain_v1.dart';
import 'package:flutter/material.dart';

import '../../beshence_sdk_flutter.dart';
import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class BeshenceAccount {
  final String id;

  BeshenceAccount({required this.id});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BeshenceAccount &&
        other.id == id;
  }

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
      final BankV1 bankV1 = BankV1(
          id: bankId,
          apiUrls: [],
          accessToken: null,
          refreshToken: null);
      await banksV1Box.put(encodeKey(bankId: bankId), bankV1);
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

  Future<String> issueToken({required String tokenId, required String scope}) async {
    return (await requireChain("tokens")).addEvent(IssueTokenV1Event(tokenId: tokenId, scope: scope));
  }

  Widget avatarButton({required BuildContext context, VoidCallback? onPressed}) {
    return IconButton(
        padding: .all(4.0),
        icon: avatar(context: context, radius: 16.0),
        onPressed: onPressed
    );
  }

  Widget avatar({required BuildContext context, required double radius}) {
    final colorScheme = Theme.of(context).colorScheme;
    bool isBackgroundDark = ThemeData.estimateBrightnessForColor(_avatarColor) == Brightness.dark;
    return CircleAvatar(
      radius: radius,
      foregroundColor: Colors.transparent,
      backgroundColor: _avatarColor,
      /*child: Text(_initials, style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      )),*/
        child: Icon(
          Icons.person_outlined,
          size: radius+8,
          color: isBackgroundDark
              ? colorScheme.surfaceContainerLowest
              : colorScheme.surfaceContainerHighest,
        )
    );
  }

  /*String get _initials {
    if (name == null || name!.trim().isEmpty) {
      return id.characters.first.toUpperCase();
    }

    final parts = name!
        .trim()
        .split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return (
        parts[0].characters.first +
            parts[1].characters.first
    ).toUpperCase();
  }*/

  Color get _avatarColor {
    // Safe 32-bit string hashing, identical across all platforms (Web, Mobile, Desktop)
    int hash = 0;
    for (int i = 0; i < id.length; i++) {
      // Mask with 0xFFFFFFFF to force 32-bit integer operations and prevent JS overflow in Web
      hash = (31 * hash + id.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    // Get a stable hue value between 0.0 and 360.0
    final double hue = (hash.abs() % 360).toDouble();

    // Fix saturation at 0.65 (vibrant but not eye-straining)
    // Fix value/brightness at 0.85 (bright enough for dark icons/text)
    return HSVColor.fromAHSV(1.0, hue, 0.65, 0.85).toColor();
  }
}

