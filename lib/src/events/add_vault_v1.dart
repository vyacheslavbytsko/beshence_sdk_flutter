import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

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

class AddVaultV1EventMapper implements BeshenceEventMapper<AddVaultV1Event> {
  @override
  String get name => "add_vault_v1";

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