import 'dart:async';

import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class IssueTokenV1Event extends BeshenceEvent {
  final String tokenId;
  final String scope;

  IssueTokenV1Event({required this.tokenId, required this.scope});
}

class IssueTokenV1EventSpec implements BeshenceEventSpec<IssueTokenV1Event> {
  @override
  String get name => "issue_token_v1";

  @override
  FutureOr<bool> apply(IssueTokenV1Event event) {
    return false;
  }

  @override
  IssueTokenV1Event fromJson(Map<String, dynamic> json) {
    return IssueTokenV1Event(tokenId: json["id"] as String, scope: json["scope"] as String);
  }

  @override
  Map<String, dynamic> toJson(IssueTokenV1Event event) {
    return {
      "id": event.tokenId,
      "scope": event.scope
    };
  }
}