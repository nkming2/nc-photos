import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/theme.dart';

class SelectionAppBar extends StatelessWidget {
  const SelectionAppBar({
    Key? key,
    required this.count,
    this.onClosePressed,
    this.actions,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        appBarTheme: AppTheme.getContextualAppBarTheme(context),
      ),
      child: SliverAppBar(
        pinned: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onClosePressed,
        ),
        title: Text(L10n.global().selectionAppBarTitle(count)),
        actions: actions,
      ),
    );
  }

  final int count;
  final VoidCallback? onClosePressed;
  final List<Widget>? actions;
}
