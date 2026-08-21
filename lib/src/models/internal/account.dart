import 'package:beshence_sdk_flutter/src/misc.dart';

import '../../../beshence_sdk_flutter.dart';
import '../../hive_objects/account_v1.dart';

class BeshenceAccountInternal {
  BeshenceAccount account;

  BeshenceAccountInternal({required this.account});

  AccountV1? get hiveV1 => accountsV1Box.get(encodeKey(accountId: account.id));
  set hiveV1(AccountV1 accountV1) => accountsV1Box.put(encodeKey(accountId: account.id), accountV1);
}