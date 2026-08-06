import 'package:beshence_sdk_flutter/beshence_sdk_flutter.dart';
import 'package:flutter/material.dart';

class BeshenceAvatarButton extends StatelessWidget {
  final BeshenceAccount account;
  final VoidCallback? onPressed;

  const BeshenceAvatarButton({super.key, required this.account, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
        icon: BeshenceAvatar(account: account, radius: 16.0),
        onPressed: onPressed
    );
  }
}

class BeshenceAvatar extends StatelessWidget {
  final BeshenceAccount account;
  final double radius;

  const BeshenceAvatar({super.key, required this.account, required this.radius});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSystemDark = theme.brightness == Brightness.dark;

    final Color iconColor = Color.alphaBlend(
      isSystemDark
          ? Colors.black.withValues(alpha: 0.75)
          : Colors.white.withValues(alpha: 0.85),
      _avatarColor,
    );

    return CircleAvatar(
        radius: radius,
        foregroundColor: Colors.transparent,
        backgroundColor: _avatarColor,
        /*child: Text(_initials, style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      )),*/
        child: Icon(
          Icons.person_outlined,
          size: radius+8,
          color: iconColor,
        )
    );
  }

  /*String get _initials {
    if (name == null || name!.trim().isEmpty) {
      return id.characters.first.toUpperCase();
    }

    final parts = name!
        .trim()
        .split(RegExp(r'\s+'));

    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }

    return (
        parts[0].characters.first +
            parts[1].characters.first
    ).toUpperCase();
  }*/

  Color get _avatarColor {
    // Safe 32-bit string hashing, identical across all platforms (Web, Mobile, Desktop)
    int hash = 0;
    for (int i = 0; i < account.id.length; i++) {
      // Mask with 0xFFFFFFFF to force 32-bit integer operations and prevent JS overflow in Web
      hash = (31 * hash + account.id.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    // Get a stable hue value between 0.0 and 360.0
    final double hue = (hash.abs() % 360).toDouble();

    // Fix saturation at 0.65 (vibrant but not eye-straining)
    // Fix value/brightness at 0.85 (bright enough for dark icons/text)
    return HSVColor.fromAHSV(1.0, hue, 0.45, 1).toColor();
  }
}
