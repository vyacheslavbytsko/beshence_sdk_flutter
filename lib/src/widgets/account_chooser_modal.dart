import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../beshence_sdk_flutter.dart';

Color buttonsBackgroundColor(BuildContext context) => Theme.of(context).colorScheme.brightness == Brightness.dark
    ? Colors.black : Colors.white;

class BeshenceAccountChooserModal extends StatelessWidget {
  final List<Widget> children;

  const BeshenceAccountChooserModal({super.key, this.children = const []});

  @override
  Widget build(BuildContext context) {
    final modalBackgroundColor = Theme.of(context).colorScheme.brightness == Brightness.dark
        ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.surfaceVariant; // surfaceContainerHighest doesn't work!!!

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.0,
      expand: false,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: modalBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              controller: scrollController,
              child: SafeArea(
                  right: false, top: false, left: false, bottom: true,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: SizedBox(
                          width: 32,
                          height: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              borderRadius: const BorderRadius.all(Radius.circular(4)),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: .start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: .max,
                                mainAxisAlignment: .spaceBetween,
                                children: [
                                  IconButton(
                                      icon: Icon(Icons.arrow_back),
                                      constraints: BoxConstraints(),
                                      style: IconButton.styleFrom(
                                        padding: .all(8),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      onPressed: () => Navigator.pop(context)),
                                  SizedBox(width: 12,),
                                  Wrap(
                                    crossAxisAlignment: .center,
                                    children: [
                                      Beshence.selectedAccount!.avatar(radius: 12),
                                      SizedBox(width: 8,),
                                      Text("Hello, User!", style: Theme.of(context).textTheme.titleLarge?.copyWith(height: 1.0), textAlign: .center,),
                                    ],
                                  ),
                                  SizedBox(width: 12,),
                                  SizedBox(width: 40), // the same as IconButton
                                ],
                              ),
                              SizedBox(height: 16.0,),
                              Flex(
                                direction: .horizontal,
                                mainAxisSize: .max,
                                mainAxisAlignment: .spaceEvenly,
                                spacing: 4,
                                children: [
                                  _TopAccountButton(
                                    icon: Icons.cloud_done_outlined,
                                    text: "Sync status:\nsynced",
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(28),
                                      topRight: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                    onTap: () {},
                                  ),
                                  _TopAccountButton(
                                    icon: Icons.account_circle_outlined,
                                    text: "Manage your\nBeshence Account",
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(28),
                                      topLeft: Radius.circular(4),
                                      bottomLeft: Radius.circular(4),
                                      bottomRight: Radius.circular(4),
                                    ),
                                    onTap: () => launchUrl(Uri.parse("https://account.beshence.com")),
                                  ),
                                ],
                              ),
                              SizedBox(height: 4),
                              BeshenceAccountChooserTile(
                                title: "Switch account",
                                leading: Icon(Icons.sync_alt),
                                trailing: Icon(Icons.arrow_drop_down),
                                connectTop: true,
                              ),
                              if(children.isNotEmpty) Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  "More from this app",
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.onPrimaryContainer),
                                ),
                              ),
                              ...children
                            ],
                          )
                      ),
                    ],
                  )
              )
          ),
        );
      },
    );
  }
}

class BeshenceAccountChooserTile extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool connectTop;
  final bool connectBottom;
  final Function()? onTap;

  const BeshenceAccountChooserTile({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.connectTop = false,
    this.connectBottom = false,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.only(
        topLeft: Radius.circular(connectTop ? 4: 28),
        topRight: Radius.circular(connectTop ? 4: 28),
        bottomLeft: Radius.circular(connectBottom ? 4: 28),
        bottomRight: Radius.circular(connectBottom ? 4: 28)
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        height: 56,
        decoration: BoxDecoration(
          color: buttonsBackgroundColor(context),
          borderRadius: borderRadius
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: .center,
              mainAxisAlignment: .spaceBetween,
              children: [
                Wrap(
                  children: [
                    if(leading != null) IconTheme(
                        data: Theme.of(context).iconTheme.copyWith(size: 20),
                        child: leading!,
                    ),
                    if(leading != null) SizedBox(width: 12,),
                    Text(title, style: Theme.of(context).textTheme.titleSmall,)
                  ],
                ),
                ?trailing
              ],
            ),
          ),
        ),
      ),
    );
  }

}

class _TopAccountButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;

  const _TopAccountButton({
    required this.icon,
    required this.text,
    required this.borderRadius,
    this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          height: 96,
          decoration: BoxDecoration(
            color: buttonsBackgroundColor(context),
            borderRadius: borderRadius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Stack(
                children: [
                  Align(
                    alignment: .topStart,
                    child: Icon(icon, size: 20),
                  ),
                  Align(
                    alignment: .bottomStart,
                    child: Text(
                      text,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}