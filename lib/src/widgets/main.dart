import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/widgets/avatar.dart';
import 'package:flutter/material.dart';

class BeshenceWidgets {
  static BeshenceAvatar avatar({
    Key? key,
    required BeshenceAccount account,
    double radius = 16.0
  }) => BeshenceAvatar(
      key: key,
      account: account,
      radius: radius
  );

  static BeshenceAvatarButton avatarButton({
    Key? key,
    required BeshenceAccount account,
    Function()? onPressed
  }) => BeshenceAvatarButton(
      key: key,
      account: account,
      onPressed: onPressed
  );
}