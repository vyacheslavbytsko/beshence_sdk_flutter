import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class ChangeVaultsPrioritiesV1Event extends BeshenceEvent {
  final List<Map<String, int>> priorities;

  ChangeVaultsPrioritiesV1Event({required this.priorities});
}

class ChangeVaultsPrioritiesV1EventSpec implements BeshenceEventSpec<ChangeVaultsPrioritiesV1Event> {
  @override
  String get name => "change_vaults_priorities_v1";

  @override
  FutureOr<void> apply(ChangeVaultsPrioritiesV1Event event) {
    // TODO: implement apply
    throw UnimplementedError();
  }

  @override
  ChangeVaultsPrioritiesV1Event fromJson(Map<String, dynamic> json) {
    return ChangeVaultsPrioritiesV1Event(
        priorities: List<Map<String, int>>.from(json['priorities'])
    );
  }

  @override
  Map<String, dynamic> toJson(ChangeVaultsPrioritiesV1Event event) {
    return {
      "priorities": event.priorities
    };
  }
}