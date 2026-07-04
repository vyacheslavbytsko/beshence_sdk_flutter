import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_ce_flutter/adapters.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';

bool initialized = false;
late final Box settingsBox;
late final Box<AccountV1> accountsV1Box;
late final Box<VaultV1> vaultsV1Box;
late final Box<ChainV1> chainsV1Box;
late final Box<EventV1> eventsV1Box;

String encodeKey({
  String? accountId,
  String? bankId,
  String? vaultId,
  String? chainName,
  String? eventId,
}) {
  final builder = BytesBuilder(copy: false);

  _appendUuid(builder, accountId);
  _appendUuid(builder, bankId);
  _appendUuid(builder, vaultId);
  _appendUuid(builder, chainName);
  _appendUuid(builder, eventId);

  return base64UrlEncode(builder.takeBytes());
}

void _appendUuid(BytesBuilder builder, String? uuidString) {
  if (uuidString == null) {
    return;
  }

  final hex = uuidString.replaceAll('-', '');

  final bytes = Uint8List(16);

  for (var i = 0; i < 16; i++) {
    final hi = _hexToInt(hex.codeUnitAt(i * 2));
    final lo = _hexToInt(hex.codeUnitAt(i * 2 + 1));

    bytes[i] = (hi << 4) | lo;
  }

  builder.add(bytes);
}

int _hexToInt(int c) {
  if (c >= 48 && c <= 57) return c - 48;  // 0-9
  if (c >= 65 && c <= 70) return c - 55;  // A-F
  if (c >= 97 && c <= 102) return c - 87; // a-f

  throw ArgumentError('Invalid hex character');
}