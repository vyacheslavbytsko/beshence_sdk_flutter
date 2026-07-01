import 'package:hive_ce_flutter/adapters.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'hive_objects/account_v1.dart';
import '../hive_registrar.g.dart';

bool _initialized = false;
late String appId;

Future<void> init() async {
  if (_initialized) return;
  await Hive.initFlutter();
  Hive.registerAdapters();
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  appId = packageInfo.packageName;
  _initialized = true;
}

Future<Box<T>> getBox<T>(String name) async =>
    Hive.isBoxOpen(name)
        ? Hive.box<T>(name)
        : await Hive.openBox<T>(name);

Future<Box<AccountV1>> getAccountsV1Box() async => await getBox<AccountV1>('beshence_${appId}_accounts_v1');