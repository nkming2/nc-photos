import 'package:flutter/material.dart';

class CollectionGridItem extends StatelessWidget {
  const CollectionGridItem({
    Key? key,
    required this.cover,
    required this.title,
    this.subtitle,
    this.subtitle2,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                      child: IconTheme(
                        data: const IconThemeData(
                          size: 20,
                          color: Colors.white,
                        ),
                        child: icon!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.start,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  subtitle ?? "",
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.start,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subtitle2?.isNotEmpty == true)
                Text(
                  subtitle2!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                ),
            ],
          ),
        ],
      ),
    );
  }

  final Widget cover;
  final String title;
  final String? subtitle;

  /// Appears after [subtitle], aligned to the end side of parent
  final String? subtitle2;
  final Widget? icon;
}
