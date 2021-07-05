import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/selectable.dart';

class AlbumGridItem extends StatelessWidget {
  AlbumGridItem({
    Key key,
    @required this.cover,
    @required this.title,
    this.subtitle,
    this.subtitle2,
    this.icon,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Selectable(
      isSelected: isSelected,
      iconSize: 48,
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  cover,
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Align(
                        alignment: AlignmentDirectional.topEnd,
                        child: Icon(
                          icon,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title ?? "",
              style: Theme.of(context).textTheme.bodyText1.copyWith(
                    color: AppTheme.getPrimaryTextColor(context),
                  ),
              textAlign: TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle ?? "",
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                          fontSize: 10,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                    textAlign: TextAlign.start,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (subtitle2?.isNotEmpty == true)
                  Text(
                    subtitle2,
                    style: Theme.of(context).textTheme.bodyText2.copyWith(
                          fontSize: 10,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  final Widget cover;
  final String title;
  final String subtitle;

  /// Appears after [subtitle], aligned to the end side of parent
  final String subtitle2;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
}
