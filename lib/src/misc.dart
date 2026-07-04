import 'dart:convert';
import 'dart:typed_data';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:hive_ce_flutter/adapters.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';

late final BeshenceEventRegistry eventsRegistry;
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
  _appendString(builder, chainName);
  _appendUuid(builder, eventId);

  return base64UrlEncode(builder.takeBytes());
}

void _appendString(BytesBuilder builder, String? value) {
  if (value == null) return;

  final length = value.length;

  if (length > 65535) {
    throw ArgumentError.value(
      value,
      'value',
      'Max length is 65535 characters',
    );
  }

  // 2 байта длины (big-endian)
  builder.addByte((length >> 8) & 0xFF);
  builder.addByte(length & 0xFF);

  for (var i = 0; i < length; i++) {
    final c = value.codeUnitAt(i);

    final isValid =
        (c >= 48 && c <= 57) ||  // 0-9
            (c >= 65 && c <= 90) ||  // A-Z
            (c >= 97 && c <= 122) || // a-z
            c == 95 ||               // _
            c == 45;                 // -

    if (!isValid) {
      throw ArgumentError.value(
        value,
        'value',
        'Invalid character in string',
      );
    }

    builder.addByte(c);
  }
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