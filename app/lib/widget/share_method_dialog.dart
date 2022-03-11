import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

enum ShareMethod {
  file,
  publicLink,
  passwordLink,
}

class ShareMethodDialog extends StatelessWidget {
  const ShareMethodDialog({
    Key? key,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return SimpleDialog(
      title: Text(L10n.global().shareMethodDialogTitle),
      children: [
        if (platform_k.isAndroid)
          SimpleDialogOption(
            child: ListTile(
              title: Text(L10n.global().shareMethodFileTitle),
              subtitle: Text(L10n.global().shareMethodFileDescription),
            ),
            onPressed: () {
              Navigator.of(context).pop(ShareMethod.file);
            },
          ),
        SimpleDialogOption(
          child: ListTile(
            title: Text(L10n.global().shareMethodPublicLinkTitle),
            subtitle: Text(L10n.global().shareMethodPublicLinkDescription),
          ),
          onPressed: () {
            Navigator.of(context).pop(ShareMethod.publicLink);
          },
        ),
        SimpleDialogOption(
          child: ListTile(
            title: Text(L10n.global().shareMethodPasswordLinkTitle),
            subtitle: Text(L10n.global().shareMethodPasswordLinkDescription),
          ),
          onPressed: () {
            Navigator.of(context).pop(ShareMethod.passwordLink);
          },
        ),
      ],
    );
  }
}
