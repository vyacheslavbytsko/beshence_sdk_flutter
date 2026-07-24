import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class InitAccountEvent extends BeshenceEvent {
  final String accountId;

  InitAccountEvent({required this.accountId});
}

class InitAccountEventSpec implements BeshenceEventSpec<InitAccountEvent> {
  @override
  String get name => "init_account";

  @override
  FutureOr<bool> apply(InitAccountEvent event) {
    // do nothing. this is one-time event so we must not handle this type of incoming events
    return true;
  }

  @override
  InitAccountEvent fromJson(Map<String, dynamic> json) {
    return InitAccountEvent(accountId: json['id'] as String);
  }

  @override
  Map<String, dynamic> toJson(InitAccountEvent event) {
    return {
      "id": event.accountId
    };
  }
}