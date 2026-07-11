import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

import '../hive_objects/vault_v1.dart';
import '../misc.dart';

class ChangeVaultsPrioritiesV1Event extends BeshenceEvent {
  final Map<String, int> priorities;

  ChangeVaultsPrioritiesV1Event({required this.priorities});
}

class ChangeVaultsPrioritiesV1EventSpec implements BeshenceEventSpec<ChangeVaultsPrioritiesV1Event> {
  @override
  String get name => "change_vaults_priorities_v1";

  @override
  FutureOr<void> apply(ChangeVaultsPrioritiesV1Event event) {
    // TODO: vaults belong to banks, so we cannot map vaultId to priority directly
    /*for(var priority in event.priorities.entries) {
      String vaultId = priority.key;
      int newPriority = priority.value;

      VaultV1? vaultV1 = vaultsV1Box.get(encodeKey(accountId: event.account!.id, vaultId: vaultId));
      if (vaultV1 != null) {
        VaultV1 newVaultV1 = VaultV1(
            id: vaultV1.id,
            accountId: vaultV1.accountId,
            bankId: vaultV1.bankId,
            priority: newPriority
        );
        vaultsV1Box.put(encodeKey(accountId: event.account!.id, vaultId: vaultId), newVaultV1);
      }
    }*/
  }

  @override
  ChangeVaultsPrioritiesV1Event fromJson(Map<String, dynamic> json) {
    return ChangeVaultsPrioritiesV1Event(
        priorities: Map<String, int>.from(json['priorities'])
    );
  }

  @override
  Map<String, dynamic> toJson(ChangeVaultsPrioritiesV1Event event) {
    return {
      "priorities": event.priorities
    };
  }
}