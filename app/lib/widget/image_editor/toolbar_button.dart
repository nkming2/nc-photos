import 'package:flutter/material.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/k.dart' as k;

/// Button in the image editor toolbar
///
/// If [activationOrder] != null, this button is considered activated. And if
/// [activationOrder] >= 0, a number will be drawn on top to represent its
/// current order.
class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSelected = false,
    this.activationOrder,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final color = !isSelected && isActivated
        ? Colors.white12
        : AppTheme.primarySwatchDark[500]!.withOpacity(0.7);
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedOpacity(
                    opacity: isSelected || isActivated ? 1 : 0,
                    duration: k.animationDurationNormal,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: color,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      icon,
                      size: 32,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.unfocusedIconColorDark,
                    ),
                  ),
                  if (isActivated && activationOrder! >= 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Text(
                          (activationOrder! + 1).toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.unfocusedIconColorDark,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color:
                    isSelected ? Colors.white : AppTheme.unfocusedIconColorDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get isActivated => activationOrder != null;

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool isSelected;
  final int? activationOrder;
}
