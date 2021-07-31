import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;

class ViewerBottomAppBar extends StatelessWidget {
  ViewerBottomAppBar({
    this.onSharePressed,
    this.onDownloadPressed,
    this.onDeletePressed,
  });

  @override
  build(BuildContext context) {
    return Container(
      height: kToolbarHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: const Alignment(0, -1),
          end: const Alignment(0, 1),
          colors: [
            Color.fromARGB(0, 0, 0, 0),
            Color.fromARGB(192, 0, 0, 0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          if (platform_k.isAndroid)
            Expanded(
              flex: 1,
              child: IconButton(
                icon: Icon(
                  Icons.share_outlined,
                  color: Colors.white.withOpacity(.87),
                ),
                tooltip: L10n.of(context).shareTooltip,
                onPressed: onSharePressed,
              ),
            ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(
                Icons.download_outlined,
                color: Colors.white.withOpacity(.87),
              ),
              tooltip: L10n.of(context).downloadTooltip,
              onPressed: onDownloadPressed,
            ),
          ),
          Expanded(
            flex: 1,
            child: IconButton(
              icon: Icon(
                Icons.delete_outlined,
                color: Colors.white.withOpacity(.87),
              ),
              tooltip: L10n.of(context).deleteTooltip,
              onPressed: onDeletePressed,
            ),
          ),
        ],
      ),
    );
  }

  final VoidCallback? onSharePressed;
  final VoidCallback? onDownloadPressed;
  final VoidCallback? onDeletePressed;
}
