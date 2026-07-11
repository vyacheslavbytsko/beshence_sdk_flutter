import 'dart:convert';
import 'dart:typed_data';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/hive_objects/bank_v1.dart';
import 'package:hive_ce_flutter/adapters.dart';

import 'hive_objects/account_v1.dart';
import 'hive_objects/chain_v1.dart';
import 'hive_objects/event_v1.dart';
import 'hive_objects/vault_v1.dart';

late final BeshenceEventRegistry eventsRegistry;
bool initialized = false;
late final Box settingsBox;
late final Box<AccountV1> accountsV1Box;
late final Box<BankV1> banksV1Box;
late final Box<VaultV1> vaultsV1Box;
late final Box<ChainV1> chainsV1Box;
late final Box<EventV1> eventsV1Box;

const int _accountBit = 1 << 0;
const int _bankBit = 1 << 1;
const int _vaultBit = 1 << 2;
const int _chainBit = 1 << 3;
const int _eventBit = 1 << 4;

class DecodedKey {
  final String? accountId;
  final String? bankId;
  final String? vaultId;
  final String? chainName;
  final String? eventId;

  const DecodedKey({
    this.accountId,
    this.bankId,
    this.vaultId,
    this.chainName,
    this.eventId,
  });
}

String encodeKey({
  String? accountId,
  String? bankId,
  String? vaultId,
  String? chainName,
  String? eventId,
}) {
  final builder = BytesBuilder(copy: false);

  var flags = 0;

  if (accountId != null) flags |= _accountBit;
  if (bankId != null) flags |= _bankBit;
  if (vaultId != null) flags |= _vaultBit;
  if (chainName != null) flags |= _chainBit;
  if (eventId != null) flags |= _eventBit;

  builder.addByte(flags);

  _appendUuid(builder, accountId);
  _appendBase32(builder, bankId);
  _appendUuid(builder, vaultId);
  _appendString(builder, chainName);
  _appendUuid(builder, eventId);

  return base64.encode(builder.takeBytes());
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

DecodedKey decodeKey(String encoded) {
  final bytes = base64.decode(encoded);

  if (bytes.isEmpty) {
    throw const FormatException('Key is empty');
  }

  var offset = 0;
  final flags = bytes[offset++];

  String? accountId;
  String? bankId;
  String? vaultId;
  String? chainName;
  String? eventId;

  if ((flags & _accountBit) != 0) {
    accountId = _readUuid(bytes, offset);
    offset += 16;
  }

  if ((flags & _bankBit) != 0) {
    final result = _readBase32(bytes, offset);
    bankId = result.$1;
    offset = result.$2;
  }

  if ((flags & _vaultBit) != 0) {
    vaultId = _readUuid(bytes, offset);
    offset += 16;
  }

  if ((flags & _chainBit) != 0) {
    final result = _readString(bytes, offset);
    chainName = result.$1;
    offset = result.$2;
  }

  if ((flags & _eventBit) != 0) {
    eventId = _readUuid(bytes, offset);
    offset += 16;
  }

  if (offset != bytes.length) {
    throw const FormatException('Trailing bytes found');
  }

  return DecodedKey(
    accountId: accountId,
    bankId: bankId,
    vaultId: vaultId,
    chainName: chainName,
    eventId: eventId,
  );
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

(String, int) _readString(Uint8List bytes, int offset) {
  if (offset + 2 > bytes.length) {
    throw const FormatException('Unexpected end of data');
  }

  final length = (bytes[offset] << 8) | bytes[offset + 1];
  offset += 2;

  if (offset + length > bytes.length) {
    throw const FormatException('Unexpected end of data');
  }

  return (
  String.fromCharCodes(bytes.sublist(offset, offset + length)),
  offset + length,
  );
}

String _readUuid(Uint8List bytes, int offset) {
  if (offset + 16 > bytes.length) {
    throw const FormatException('Unexpected end of data');
  }

  final buffer = StringBuffer();

  for (var i = 0; i < 16; i++) {
    buffer.write(bytes[offset + i].toRadixString(16).padLeft(2, '0'));
  }

  final hex = buffer.toString();

  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20, 32)}';
}

int _hexToInt(int c) {
  if (c >= 48 && c <= 57) return c - 48;  // 0-9
  if (c >= 65 && c <= 70) return c - 55;  // A-F
  if (c >= 97 && c <= 102) return c - 87; // a-f

  throw ArgumentError('Invalid hex character');
}

void _appendBase32(BytesBuilder builder, String? value) {
  if (value == null) return;

  final length = value.length;

  if (length > 65535) {
    throw ArgumentError.value(
      value,
      'value',
      'Max length is 65535 characters',
    );
  }

  builder.addByte((length >> 8) & 0xFF);
  builder.addByte(length & 0xFF);

  var buffer = 0;
  var bits = 0;

  for (final c in value.codeUnits) {
    final v = _base32ToInt(c);

    buffer = (buffer << 5) | v;
    bits += 5;

    while (bits >= 8) {
      bits -= 8;
      builder.addByte((buffer >> bits) & 0xff);
    }
  }

  if (bits > 0) {
    builder.addByte((buffer << (8 - bits)) & 0xff);
  }
}

(String, int) _readBase32(Uint8List bytes, int offset) {
  if (offset + 2 > bytes.length) {
    throw const FormatException('Unexpected end of data');
  }

  final length = (bytes[offset] << 8) | bytes[offset + 1];
  offset += 2;

  final byteCount = (length * 5 + 7) ~/ 8;

  if (offset + byteCount > bytes.length) {
    throw const FormatException('Unexpected end of data');
  }

  var buffer = 0;
  var bits = 0;
  var pos = offset;

  final result = StringBuffer();

  for (var i = 0; i < length; i++) {
    while (bits < 5) {
      buffer = (buffer << 8) | bytes[pos++];
      bits += 8;
    }

    bits -= 5;
    final value = (buffer >> bits) & 0x1f;

    result.writeCharCode(_intToBase32(value));
  }

  return (result.toString(), offset + byteCount);
}

int _base32ToInt(int c) {
  if (c >= 65 && c <= 90) {
    // A-Z
    return c - 65;
  }

  if (c >= 50 && c <= 55) {
    // 2-7
    return c - 24;
  }

  throw ArgumentError('Invalid Base32 character');
}

int _intToBase32(int value) {
  if (value < 26) {
    return value + 65;
  }

  if (value < 32) {
    return value + 24;
  }

  throw ArgumentError('Invalid Base32 value');
}