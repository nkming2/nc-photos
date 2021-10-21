import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/dir_picker.dart';

class ShareFolderPickerArguments {
  const ShareFolderPickerArguments(this.account, this.initialValue);

  final Account account;
  final String initialValue;
}

class ShareFolderPicker extends StatefulWidget {
  static const routeName = "/share-folder-picker";

  static Route buildRoute(ShareFolderPickerArguments args) =>
      MaterialPageRoute<String>(
        builder: (context) => ShareFolderPicker.fromArgs(args),
      );

  const ShareFolderPicker({
    Key? key,
    required this.account,
    required this.initialValue,
  }) : super(key: key);

  ShareFolderPicker.fromArgs(ShareFolderPickerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          initialValue: args.initialValue,
        );

  @override
  createState() => _ShareFolderPickerState();

  final Account account;
  final String initialValue;
}

class _ShareFolderPickerState extends State<ShareFolderPicker> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: _buildContent(context),
      ),
    );
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
                  L10n.global().settingsShareFolderDialogTitle,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child:
                      Text(L10n.global().settingsShareFolderPickerDescription),
                ),
              ],
            ),
          ),
          Expanded(
            child: DirPicker(
              key: _pickerKey,
              account: widget.account,
              rootDir: api_util.getWebdavRootUrlRelative(widget.account),
              initialPicks: [
                if (widget.initialValue.isNotEmpty)
                  File(
                    path:
                        "${api_util.getWebdavRootUrlRelative(widget.account)}/${widget.initialValue}",
                  ),
              ],
              isMultipleSelections: false,
              onConfirmed: (picks) => _onPickerConfirmed(context, picks),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _onDefaultPressed,
                  child: Text(L10n.global().defaultButtonLabel),
                ),
                ElevatedButton(
                  onPressed: _onConfirmPressed,
                  child: Text(L10n.global().confirmButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onDefaultPressed() {
    Navigator.of(context).pop("");
  }

  void _onConfirmPressed() {
    _pickerKey.currentState?.confirm();
  }

  void _onPickerConfirmed(BuildContext context, List<File> picks) {
    if (picks.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().albumDirPickerListEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
    } else {
      _log.info(
          "[_onPickerConfirmed] Picked: ${picks.map((e) => e.strippedPath).toReadableString()}");
      Navigator.of(context).pop(picks.first.strippedPath);
    }
  }

  final _pickerKey = GlobalKey<DirPickerState>();

  static final _log =
      Logger("widget.share_folder_picker._ShareFolderPickerState");
}
