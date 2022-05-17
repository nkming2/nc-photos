import 'package:flutter/material.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/object_extension.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';

class DonationDialogHandler {
  Future<void> showIfNeeded(BuildContext context) async {
    final last = Pref().getLastDonationDialogTime();
    if (last == null) {
      // first time
      final firstRun =
          (Pref().getFirstRunTime()?.run(DateTime.fromMillisecondsSinceEpoch) ??
                  DateTime.now())
              .toUtc();
      final now = DateTime.now().toUtc();
      if (now.isAfter(firstRun) &&
          now.difference(firstRun) < const Duration(days: 14)) {
        // unnecessary
        return;
      } else {
        return _show(context);
      }
    }
  }

  Future<void> _show(BuildContext context) async {
    final result = await showDialog<_DonationDialogResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DonationDialog(),
    );
    if (Pref().shouldRemindDonationLaterOr()) {
      await Pref().setShouldRemindDonationLater(false);
    }
    await Pref()
        .setLastDonationDialogTime(DateTime.now().millisecondsSinceEpoch);
    switch (result ?? _DonationDialogResult.ignore) {
      case _DonationDialogResult.ignore:
        // :(
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: const Text(
                "You can find the donation link in Settings > About if you change your mind later"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
        break;

      case _DonationDialogResult.remindLater:
        // :)
        await Pref().setShouldRemindDonationLater(true);
        SnackBarManager().showSnackBar(const SnackBar(
          content: Text("Thank you, we will remind you tomorrow"),
          duration: k.snackBarDurationShort,
        ));
        break;

      case _DonationDialogResult.visitLink:
        // :D
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            content: const Text("Thank you for your support!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          ),
        );
        break;
    }
  }
}

enum _DonationDialogResult {
  ignore,
  remindLater,
  visitLink,
}

class _DonationDialog extends StatelessWidget {
  const _DonationDialog({
    Key? key,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return AppTheme(
      child: AlertDialog(
        title: const Text("We need your help"),
        content: const Text("This project is severely underfunded."
            " If you find this app useful, please consider donating to support it."
            " Your donation will ensure this project to remain under developement and stay open source in the future."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_DonationDialogResult.ignore);
            },
            child: const Text("IGNORE"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(_DonationDialogResult.remindLater);
            },
            child: const Text("REMIND ME LATER"),
          ),
          ElevatedButton(
            onPressed: () {
              launch("https://bit.ly/3wQOHPZ");
              Navigator.of(context).pop(_DonationDialogResult.visitLink);
            },
            child: const Text("DONATE"),
          ),
        ],
      ),
    );
  }
}
