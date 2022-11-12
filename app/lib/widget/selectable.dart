import 'package:flutter/material.dart';
import 'package:nc_photos/k.dart' as k;

// Overlay a check mark if an item is selected
class Selectable extends StatelessWidget {
  const Selectable({
    Key? key,
    required this.child,
    this.isSelected = false,
    required this.iconSize,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: borderRadius,
              ),
            ),
          ),
        AnimatedScale(
          scale: isSelected ? .85 : 1,
          curve: Curves.easeInOut,
          duration: k.animationDurationNormal,
          child: child,
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            opacity: isSelected ? 1 : 0,
            duration: k.animationDurationNormal,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Icon(
                  Icons.circle,
                  size: iconSize,
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                Icon(
                  Icons.check_circle_outlined,
                  size: iconSize,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
        if (onTap != null || onLongPress != null)
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: borderRadius,
              ),
            ),
          ),
      ],
    );
  }

  final Widget child;
  final bool isSelected;
  final double iconSize;
  final BorderRadius? borderRadius;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
}
