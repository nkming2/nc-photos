import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/event/event.dart';
import 'package:nc_photos/help_utils.dart' as help_utils;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/account_picker_dialog.dart';
import 'package:nc_photos/widget/settings.dart';

/// AppBar for home screens
class HomeSliverAppBar extends StatefulWidget {
  const HomeSliverAppBar({
    Key? key,
    required this.account,
    this.actions,
    this.menuActions,
    this.onSelectedMenuActions,
  }) : super(key: key);

  @override
  createState() => _HomeSliverAppBarState();

  final Account account;

  /// Screen specific action buttons
  final List<Widget>? actions;

  /// Screen specific actions under the overflow menu. The value of each item
  /// much >= 0
  final List<PopupMenuEntry<int>>? menuActions;
  final void Function(int)? onSelectedMenuActions;
}

class _HomeSliverAppBarState extends State<HomeSliverAppBar> {
  @override
  initState() {
    super.initState();
    _prefUpdatedListener.begin();
  }

  @override
  dispose() {
    _prefUpdatedListener.end();
    super.dispose();
  }

  @override
  build(BuildContext context) {
    final accountLabel = AccountPref.of(widget.account).getAccountLabel();
    return SliverAppBar(
      title: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => AccountPickerDialog(
              account: widget.account,
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Stack(
                children: [
                  if (widget.account.scheme == "http")
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
                      accountLabel ?? widget.account.address,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (accountLabel == null)
                      Text(
                        widget.account.username2,
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
      actions: (widget.actions ?? []) +
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
              icon: Pref().isAutoUpdateCheckAvailableOr()
                  ? Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Icon(Icons.adaptive.more),
                        Positioned.directional(
                          textDirection: Directionality.of(context),
                          end: 0,
                          top: 0,
                          child: const Icon(
                            Icons.circle,
                            color: Colors.red,
                            size: 8,
                          ),
                        ),
                      ],
                    )
                  : null,
              tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
              itemBuilder: (context) =>
                  (widget.menuActions ?? []) +
                  [
                    PopupMenuItem(
                      value: _menuValueAbout,
                      child: Stack(
                        fit: StackFit.passthrough,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 8),
                            child: Text(L10n.global().settingsMenuLabel),
                          ),
                          if (Pref().isAutoUpdateCheckAvailableOr())
                            Positioned.directional(
                              textDirection: Directionality.of(context),
                              end: 0,
                              top: 0,
                              child: const Icon(
                                Icons.circle,
                                color: Colors.red,
                                size: 8,
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: _menuValueHelp,
                      child: Text(L10n.global().helpTooltip),
                    ),
                  ],
              onSelected: (option) {
                if (option >= 0) {
                  widget.onSelectedMenuActions?.call(option);
                } else {
                  if (option == _menuValueAbout) {
                    Navigator.of(context).pushNamed(Settings.routeName,
                        arguments: SettingsArguments(widget.account));
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

  void _onPrefUpdated(PrefUpdatedEvent ev) {
    if (ev.key == PrefKey.isAutoUpdateCheckAvailable) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  late final _prefUpdatedListener =
      AppEventListener<PrefUpdatedEvent>(_onPrefUpdated);

  static const _menuValueAbout = -1;
  static const _menuValueHelp = -2;
}
