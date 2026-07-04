import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class AddVaultV1Event extends BeshenceEvent<AddVaultV1Event> {
  final String address;
  final String vaultId;
  final String bankId;
  final DateTime addedAt;

  AddVaultV1Event({
    super.name="add_vault_v1",
    required this.address,
    required this.vaultId,
    required this.bankId,
    required this.addedAt
  });

  @override
  AddVaultV1Event fromJson(Map<String, dynamic> json) {
    return AddVaultV1Event(
        address: json['address'],
        vaultId: json['vaultId'],
        bankId: json['bankId'],
        addedAt: DateTime.parse(json["addedAt"])
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "address": address,
      "vaultId": vaultId,
      "bankId": bankId,
      "addedAt": addedAt.toIso8601String()
    };
  }

}