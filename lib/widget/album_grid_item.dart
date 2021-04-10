import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/theme.dart';

class AlbumGridItem extends StatelessWidget {
  AlbumGridItem({
    Key key,
    @required this.cover,
    @required this.title,
    this.subtitle,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: cover,
              ),
              const SizedBox(height: 8),
              Text(
                title ?? "",
                style: Theme.of(context).textTheme.bodyText1,
                textAlign: TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle ?? "",
                style: Theme.of(context).textTheme.bodyText2.copyWith(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.start,
                maxLines: 1,
              ),
            ],
          ),
        ),
        if (isSelected)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.getSelectionOverlayColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        if (isSelected)
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Icon(
                Icons.check_circle_outlined,
                size: 48,
                color: AppTheme.getSelectionCheckColor(context),
              ),
            ),
          ),
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        )
      ],
    );
  }

  final Widget cover;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
}
