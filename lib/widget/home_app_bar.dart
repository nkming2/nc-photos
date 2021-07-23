import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/account_picker_dialog.dart';
import 'package:nc_photos/widget/settings.dart';

/// AppBar for home screens
class HomeSliverAppBar extends StatelessWidget {
  HomeSliverAppBar({
    Key? key,
    required this.account,
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
              Stack(
                children: [
                  if (account.scheme == "http")
                    Icon(
                      Icons.no_encryption_outlined,
                      color: Colors.orange,
                    )
                  else
                    Icon(
                      Icons.https,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.url.substring(account.scheme.length + 3),
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
            Switch(
              value: Theme.of(context).brightness == Brightness.dark,
              onChanged: _onDarkModeChanged,
              activeColor: AppTheme.getAppBarDarkModeSwitchColor(context),
              inactiveThumbColor:
                  AppTheme.getAppBarDarkModeSwitchColor(context),
              activeTrackColor:
                  AppTheme.getAppBarDarkModeSwitchTrackColor(context),
              activeThumbImage:
                  const AssetImage("assets/ic_dark_mode_switch_24dp.png"),
              inactiveThumbImage:
                  const AssetImage("assets/ic_dark_mode_switch_24dp.png"),
            ),
            PopupMenuButton<int>(
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              itemBuilder: (context) =>
                  (menuActions ?? []) +
                  [
                    PopupMenuItem(
                      value: _menuValueAbout,
                      child:
                          Text(AppLocalizations.of(context)!.settingsMenuLabel),
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

  void _onDarkModeChanged(bool value) {
    Pref.inst().setDarkTheme(value).then((_) {
      KiwiContainer().resolve<EventBus>().fire(ThemeChangedEvent());
    });
  }

  final Account account;

  /// Screen specific action buttons
  final List<Widget>? actions;

  /// Screen specific actions under the overflow menu. The value of each item
  /// much >= 0
  final List<PopupMenuEntry<int>>? menuActions;
  final void Function(int)? onSelectedMenuActions;

  static const _menuValueAbout = -1;
}
