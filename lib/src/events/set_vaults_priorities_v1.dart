import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class SetVaultsPrioritiesV1Event extends BeshenceEvent {
  final Map<String, int> priorities;

  SetVaultsPrioritiesV1Event({required this.priorities});
}

class SetVaultsPrioritiesV1EventSpec implements BeshenceEventSpec<SetVaultsPrioritiesV1Event> {
  @override
  String get name => "set_vaults_priorities_v1";

  @override
  FutureOr<bool> apply(SetVaultsPrioritiesV1Event event) {
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
    return false;
  }

  @override
  SetVaultsPrioritiesV1Event fromJson(Map<String, dynamic> json) {
    return SetVaultsPrioritiesV1Event(
        priorities: Map<String, int>.from(json['priorities'])
    );
  }

  @override
  Map<String, dynamic> toJson(SetVaultsPrioritiesV1Event event) {
    return {
      "priorities": event.priorities
    };
  }
}