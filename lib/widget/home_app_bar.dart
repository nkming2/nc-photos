import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/help_utils.dart' as help_utils;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/account_picker_dialog.dart';
import 'package:nc_photos/widget/settings.dart';
import 'package:url_launcher/url_launcher.dart';

/// AppBar for home screens
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({
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
                    const Icon(
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
                      account.username.toString(),
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
            if (!Pref().isFollowSystemThemeOr(false))
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
                      child: Text(L10n.global().settingsMenuLabel),
                    ),
                    PopupMenuItem(
                      value: _menuValueHelp,
                      child: Text(L10n.global().helpTooltip),
                    ),
                  ],
              onSelected: (option) {
                if (option >= 0) {
                  onSelectedMenuActions?.call(option);
                } else {
                  if (option == _menuValueAbout) {
                    Navigator.of(context).pushNamed(Settings.routeName,
                        arguments: SettingsArguments(account));
                  } else if (option == _menuValueHelp) {
                    launch(help_utils.mainUrl);
                  }
                }
              },
            ),
          ],
    );
  }

  void _onDarkModeChanged(bool value) {
    Pref().setDarkTheme(value).then((_) {
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
  static const _menuValueHelp = -2;
}
