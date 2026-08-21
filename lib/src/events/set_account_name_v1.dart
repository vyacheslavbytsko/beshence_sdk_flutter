import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class SetAccountNameV1Event extends BeshenceEvent {
  final String name;

  SetAccountNameV1Event({required this.name});
}

class SetAccountNameV1EventSpec implements BeshenceEventSpec<SetAccountNameV1Event> {
  @override
  String get name => "set_account_name_v1";

  @override
  FutureOr<bool> apply(SetAccountNameV1Event event) {
    event.account!.internal.hiveV1!.set(name: event.name);
    return true;
  }

  @override
  SetAccountNameV1Event fromJson(Map<String, dynamic> json) {
    return SetAccountNameV1Event(
        name: json['name']
    );
  }

  @override
  Map<String, dynamic> toJson(SetAccountNameV1Event event) {
    return {
      "name": event.name
    };
  }
}