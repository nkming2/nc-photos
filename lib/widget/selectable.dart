import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/theme.dart';

// Overlay a check mark if an item is selected
class Selectable extends StatelessWidget {
  Selectable({
    Key key,
    @required this.child,
    this.isSelected = false,
    @required this.iconSize,
    this.borderRadius,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getSelectionOverlayColor(context),
                borderRadius: borderRadius,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Icon(
                  Icons.check_circle_outlined,
                  size: iconSize,
                  color: AppTheme.getSelectionCheckColor(context),
                ),
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
  final BorderRadiusGeometry borderRadius;

  final VoidCallback onTap;
  final VoidCallback onLongPress;
}
