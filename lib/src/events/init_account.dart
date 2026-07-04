import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';

class InitAccountEvent extends BeshenceEvent<InitAccountEvent> {
  final String accountId;

  InitAccountEvent({super.name="init_account", required this.accountId});

  @override
  InitAccountEvent fromJson(Map<String, dynamic> json) {
    return InitAccountEvent(accountId: json['id'] as String);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "id": accountId
    };
  }

}