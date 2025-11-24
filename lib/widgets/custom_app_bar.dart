import 'package:flutter/material.dart';
import 'package:dermai/screens/conversation_list_screen.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;
  final double elevation;
  final double height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onMenuPressed;

  const CustomAppBar({
    Key? key,
    this.title,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
    this.elevation = 0,
    this.height = kToolbarHeight,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      elevation: elevation,
      titleSpacing: 0,
      centerTitle: false,
      title: Padding(
        padding: padding,
        child: Row(
          children: [
            if (showBackButton)
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.arrow_back,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
            Expanded(child: title ?? const SizedBox()),
            if (actions != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!.map((widget) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: widget,
                  );
                }).toList(),
              )
            else
              const SizedBox(width: 8),
            if (onMenuPressed != null)
              GestureDetector(
                onTap: onMenuPressed,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ),
          ],
        ),
      ),
      toolbarHeight: height,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);
}
