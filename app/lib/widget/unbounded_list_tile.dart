import 'package:flutter/material.dart';
import 'package:nc_photos/theme.dart';

/// A [ListTile]-like widget with unbounded height
class UnboundedListTile extends StatelessWidget {
  const UnboundedListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DefaultTextStyle(
                  style: Theme.of(context).textTheme.subtitle1!,
                  child: title,
                ),
                if (subtitle != null)
                  DefaultTextStyle(
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                    child: subtitle!,
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: content,
      );
    } else {
      return content;
    }
  }

  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
}
