import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/misc.dart';

class BeshenceVault {
  final String id;
  final BeshenceAccount account;
  
  int get priority => vaultsV1Box.get(encodeKey(accountId: account.id, vaultId: id))!.priority;

  BeshenceVault({required this.id, required this.account});
}