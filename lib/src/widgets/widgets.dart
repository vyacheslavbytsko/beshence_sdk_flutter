import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:beshence_sdk_flutter/src/widgets/account_chooser_modal.dart';
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

  static BeshenceAccountChooserModal accountChooserModal({
    List<Widget> children = const []
  }) => BeshenceAccountChooserModal(
      children: children
  );

  static void showAccountChooserModal({required BuildContext context, List<Widget> children = const []}) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => BeshenceWidgets.accountChooserModal(
            children: children
        )
    );
  }

  static BeshenceAccountChooserTile accountChooserTile({
    Key? key,
    required String title,
    Widget? leading,
    Widget? trailing,
    bool connectTop = false,
    bool connectBottom = false,
    Function()? onTap
  }) => BeshenceAccountChooserTile(
      key: key,
      title: title,
      leading: leading,
      trailing: trailing,
      connectTop: connectTop,
      connectBottom: connectBottom,
      onTap: onTap
  );
}