import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/vault_v1.dart';
import 'package:beshence_sdk_flutter/src/misc.dart';

class AddVaultV1Event extends BeshenceEvent {
  final String vaultId;
  final String bankId;
  final int priority;
  final DateTime addedAt;

  AddVaultV1Event({
    required this.vaultId,
    required this.bankId,
    required this.priority,
    required this.addedAt
  });
}

class AddVaultV1EventSpec implements BeshenceEventSpec<AddVaultV1Event> {
  @override
  String get name => "add_vault_v1";

  @override
  FutureOr<void> apply(AddVaultV1Event event) {
    if(!banksV1Box.containsKey(encodeKey(bankId: event.bankId))) {
      BankV1 bankV1 = BankV1(
          id: event.bankId,
          apiUrls: [],
          accessToken: null,
          refreshToken: null
      );
      banksV1Box.put(encodeKey(bankId: event.bankId), bankV1);
    }
    VaultV1 vaultV1 = VaultV1(
        id: event.vaultId,
        accountId: event.account!.id,
        bankId: event.bankId,
        priority: event.priority
    );
    vaultsV1Box.put(encodeKey(accountId: event.account!.id, bankId: event.bankId, vaultId: event.vaultId), vaultV1);
  }

  @override
  AddVaultV1Event fromJson(Map<String, dynamic> json) {
    return AddVaultV1Event(
        vaultId: json['vault_id'],
        bankId: json['bank_id'],
        priority: json['priority'],
        addedAt: DateTime.parse(json["added_at"])
    );
  }

  @override
  Map<String, dynamic> toJson(AddVaultV1Event event) {
    return {
      "vault_id": event.vaultId,
      "bank_id": event.bankId,
      "priority": event.priority,
      "added_at": event.addedAt.toIso8601String()
    };
  }
}