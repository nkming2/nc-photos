import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/dir_picker_mixin.dart';

class AlbumDirPickerArguments {
  AlbumDirPickerArguments(this.account);

  final Account account;
}

class AlbumDirPicker extends StatefulWidget {
  static const routeName = "/album-dir-picker";

  AlbumDirPicker({
    Key key,
    @required this.account,
  }) : super(key: key);

  AlbumDirPicker.fromArgs(AlbumDirPickerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _AlbumDirPickerState();

  final Account account;
}

class _AlbumDirPickerState extends State<AlbumDirPicker>
    with DirPickerMixin<AlbumDirPicker> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: _buildContent(context),
      ),
    );
  }

  @override
  getPickerRoot() {
    final root = api_util.getWebdavRootUrlRelative(widget.account);
    if (widget.account.roots.length == 1) {
      return "$root/${widget.account.roots.first}";
    } else {
      return root;
    }
  }

  @override
  getAccount() => widget.account;

  @override
  canPickDir(File dir) {
    final root = api_util.getWebdavRootUrlRelative(widget.account);
    return widget.account.roots
        .any((r) => dir.path == "$root/$r" || dir.path.startsWith("$root/$r/"));
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).albumDirPickerHeaderText,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    AppLocalizations.of(context).albumDirPickerSubHeaderText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: buildDirPicker(context),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                ElevatedButton(
                  onPressed: () => _onConfirmPressed(context),
                  child: Text(AppLocalizations.of(context).confirmButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onConfirmPressed(BuildContext context) {
    final picked = getPickedDirs();
    if (picked.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            AppLocalizations.of(context).albumDirPickerListEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      _log.info(
          "[_onConfirmPressed] Picked: ${picked.map((e) => e.strippedPath).toReadableString()}");
      Navigator.of(context).pop(picked);
    }
  }

  static final _log = Logger("widget.album_dir_picker._AlbumDirPickerState");
}
