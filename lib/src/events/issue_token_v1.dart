import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class IssueTokenV1Event extends BeshenceEvent {
  final String token;
  final String scope;

  IssueTokenV1Event({required this.token, required this.scope});
}

class IssueTokenV1EventSpec implements BeshenceEventSpec<IssueTokenV1Event> {
  @override
  String get name => "issue_token_v1";

  @override
  FutureOr<void> apply(IssueTokenV1Event event) {
    // TODO
  }

  @override
  IssueTokenV1Event fromJson(Map<String, dynamic> json) {
    return IssueTokenV1Event(token: json["token"] as String, scope: json["scope"] as String);
  }

  @override
  Map<String, dynamic> toJson(IssueTokenV1Event event) {
    return {
      "token": event.token,
      "scope": event.scope
    };
  }
}