import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/help_utils.dart' as help_utils;
import 'package:nc_photos/pref.dart';
import 'package:url_launcher/url_launcher.dart';

class SharedAlbumInfoDialog extends StatefulWidget {
  const SharedAlbumInfoDialog({
    Key? key,
  }) : super(key: key);

  @override
  createState() => _SharedAlbumInfoDialogState();
}

class _SharedAlbumInfoDialogState extends State<SharedAlbumInfoDialog> {
  @override
  dispose() {
    super.dispose();
    Pref().setHasShownSharedAlbumInfo(true);
  }

  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().sharedAlbumInfoDialogTitle),
      content: Text(L10n.global().sharedAlbumInfoDialogContent),
      actions: [
        TextButton(
          onPressed: () => _onSkipPressed(context),
          child: Text(L10n.global().skipButtonLabel),
        ),
        TextButton(
          onPressed: _onLearnMorePressed,
          child: Text(L10n.global().learnMoreButtonLabel),
        ),
      ],
    );
  }

  void _onSkipPressed(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _onLearnMorePressed() {
    launch(help_utils.sharedAlbumLimitationsUrl);
    Navigator.of(context).pop();
  }
}
