import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/account_picker_dialog.dart';
import 'package:nc_photos/widget/app_bar_circular_progress_indicator.dart';
import 'package:nc_photos/widget/app_bar_title_container.dart';
import 'package:nc_photos/widget/translucent_sliver_app_bar.dart';

/// AppBar for home screens
class HomeSliverAppBar extends StatelessWidget {
  const HomeSliverAppBar({
    Key? key,
    required this.account,
    this.actions,
    this.menuActions,
    this.onSelectedMenuActions,
    this.isShowProgressIcon = false,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    final accountLabel = AccountPref.of(account).getAccountLabel();
    return TranslucentSliverAppBar(
      title: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => const AccountPickerDialog(),
          );
        },
        child: AppBarTitleContainer(
          title: Row(
            children: [
              account.scheme == "http"
                  ? Icon(
                      Icons.no_encryption_outlined,
                      color: Theme.of(context).colorScheme.error,
                      size: 16,
                    )
                  : Icon(
                      Icons.https,
                      color: Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
              Expanded(
                child: Text(
                  accountLabel ?? account.address,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
          subtitle: accountLabel == null ? Text(account.username2) : null,
        ),
      ),
      scrolledUnderBackgroundColor:
          Theme.of(context).homeNavigationBarBackgroundColor,
      floating: true,
      automaticallyImplyLeading: false,
      actions: [
        ...actions ?? [],
        if (menuActions?.isNotEmpty == true)
          PopupMenuButton<int>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (_) => menuActions!,
            onSelected: (option) {
              if (option >= 0) {
                onSelectedMenuActions?.call(option);
              }
            },
          ),
        _ProfileIconView(
          account: account,
          isProcessing: isShowProgressIcon,
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => const AccountPickerDialog(),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  final Account account;

  /// Screen specific action buttons
  final List<Widget>? actions;

  /// Screen specific actions under the overflow menu. The value of each item
  /// much >= 0
  final List<PopupMenuEntry<int>>? menuActions;
  final void Function(int)? onSelectedMenuActions;
  final bool isShowProgressIcon;
}

class _ProfileIconView extends StatelessWidget {
  const _ProfileIconView({
    required this.account,
    required this.isProcessing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: _size,
      child: Stack(
        children: [
          isProcessing
              ? const AppBarCircularProgressIndicator()
              : ClipRRect(
                  borderRadius: BorderRadius.circular(_size / 2),
                  child: CachedNetworkImage(
                    imageUrl: api_util.getAccountAvatarUrl(account, 64),
                    fadeInDuration: const Duration(),
                    filterQuality: FilterQuality.high,
                  ),
                ),
          Positioned.fill(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(_size / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  final Account account;
  final bool isProcessing;
  final VoidCallback onTap;

  static const _size = 40.0;
}
