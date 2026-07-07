import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/misc.dart';

class BeshenceVault {
  final String id;
  final BeshenceAccount account;
  final BeshenceBank bank;
  
  int get priority => vaultsV1Box.get(encodeKey(accountId: account.id, bankId: bank.id, vaultId: id))!.priority;

  BeshenceVault({required this.id, required this.account, required this.bank});

  Future<String?> get remoteLastEventId async {

  }
}