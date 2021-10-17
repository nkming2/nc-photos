import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/widget/dir_picker_mixin.dart';
import 'package:nc_photos/widget/processing_dialog.dart';

class RootPickerArguments {
  RootPickerArguments(this.account);

  final Account account;
}

class RootPicker extends StatefulWidget {
  static const routeName = "/root-picker";

  static Route buildRoute(RootPickerArguments args) =>
      MaterialPageRoute<Account>(
        builder: (context) => RootPicker.fromArgs(args),
      );

  const RootPicker({
    Key? key,
    required this.account,
  }) : super(key: key);

  RootPicker.fromArgs(RootPickerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _RootPickerState();

  final Account account;
}

class _RootPickerState extends State<RootPicker>
    with DirPickerMixin<RootPicker> {
  @override
  initState() {
    super.initState();
    _initAccount();
  }

  void _initAccount() async {
    try {
      const fileSrc = FileWebdavDataSource();
      final files = <File>[];
      for (final r in widget.account.roots) {
        if (r.isNotEmpty) {
          _isIniting = true;
          _ensureInitDialog();
          files.add(await LsSingleFile(fileSrc)(widget.account,
              "${api_util.getWebdavRootUrlRelative(widget.account)}/$r"));
        }
      }
      setState(() {
        _isIniting = false;
        pickAll(files);
      });
    } catch (e) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    } finally {
      _dismissInitDialog();
    }
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: _buildContent(context),
      ),
    );
  }

  @override
  getPickerRoot() => api_util.getWebdavRootUrlRelative(widget.account);

  @override
  getAccount() => widget.account;

  Widget _buildContent(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  L10n.global().rootPickerHeaderText,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    L10n.global().rootPickerSubHeaderText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IgnorePointer(
              ignoring: _isIniting,
              child: buildDirPicker(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _onSkipPressed(context),
                  child: Text(L10n.global().skipButtonLabel),
                ),
                ElevatedButton(
                  onPressed: () => _onConfirmPressed(context),
                  child: Text(L10n.global().confirmButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSkipPressed(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content:
                  Text(L10n.global().rootPickerSkipConfirmationDialogContent),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            )).then((value) {
      if (value == true) {
        Navigator.of(context).pop(widget.account.copyWith(roots: [""]));
      }
    });
  }

  void _onConfirmPressed(BuildContext context) {
    final roots = getPickedDirs().map((e) => e.strippedPath).toList();
    if (roots.isEmpty) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().rootPickerListEmptyNotification),
        duration: k.snackBarDurationNormal,
      ));
      return;
    }
    final newAccount = widget.account.copyWith(roots: roots);
    _log.info("[_onConfirmPressed] Account is good: $newAccount");
    Navigator.of(context).pop(newAccount);
  }

  void _ensureInitDialog() {
    if (_isInitDialogShown) {
      return;
    }
    _isInitDialogShown = true;
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (context) => ProcessingDialog(
            text: L10n.global().genericProcessingDialogContent),
      );
    });
  }

  void _dismissInitDialog() {
    if (!_isInitDialogShown) {
      return;
    }
    Navigator.of(context).pop();
  }

  bool _isIniting = false;
  bool _isInitDialogShown = false;

  static final _log = Logger("widget.root_picker._RootPickerState");
}
