import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/account_picker_dialog.dart';
import 'package:nc_photos/widget/settings.dart';

/// AppBar for home screens
class HomeSliverAppBar extends StatelessWidget {
  HomeSliverAppBar({
    Key key,
    @required this.account,
    this.actions,
    this.menuActions,
    this.onSelectedMenuActions,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return SliverAppBar(
      title: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AccountPickerDialog(
              account: account,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(
                Icons.cloud,
                color: AppTheme.getCloudIconColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.url,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      account.username,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floating: true,
      automaticallyImplyLeading: false,
      actions: (actions ?? []) +
          [
            PopupMenuButton(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              itemBuilder: (context) =>
                  (menuActions ?? []) +
                  [
                    PopupMenuItem(
                      value: _menuValueAbout,
                      child:
                          Text(AppLocalizations.of(context).settingsMenuLabel),
                    ),
                  ],
              onSelected: (option) {
                if (option >= 0) {
                  onSelectedMenuActions?.call(option);
                } else {
                  if (option == _menuValueAbout) {
                    Navigator.of(context).pushNamed(Settings.routeName,
                        arguments: SettingsArguments(account));
                  }
                }
              },
            ),
          ],
    );
  }

  final Account account;

  /// Screen specific action buttons
  final List<Widget> actions;

  /// Screen specific actions under the overflow menu. The value of each item
  /// much >= 0
  final List<PopupMenuEntry<int>> menuActions;
  final void Function(int) onSelectedMenuActions;

  static const _menuValueAbout = -1;
}
