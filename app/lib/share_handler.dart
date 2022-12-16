import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/share.dart';
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/remote_storage_util.dart' as remote_storage_util;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/copy.dart';
import 'package:nc_photos/use_case/create_dir.dart';
import 'package:nc_photos/use_case/create_share.dart';
import 'package:nc_photos/use_case/download_file.dart';
import 'package:nc_photos/use_case/download_preview.dart';
import 'package:nc_photos/use_case/inflate_file_descriptor.dart';
import 'package:nc_photos/use_case/share_local.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:nc_photos/widget/share_link_multiple_files_dialog.dart';
import 'package:nc_photos/widget/share_method_dialog.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:tuple/tuple.dart';

part 'share_handler.g.dart';

/// Handle sharing to other apps
@npLog
class ShareHandler {
  ShareHandler(
    this._c, {
    required this.context,
    this.clearSelection,
  })  : assert(require(_c)),
        assert(InflateFileDescriptor.require(_c));

  static bool require(DiContainer c) => true;

  Future<void> shareLocalFiles(List<LocalFile> files) async {
    if (!isSelectionCleared) {
      clearSelection?.call();
    }
    final c = KiwiContainer().resolve<DiContainer>();
    var hasShownError = false;
    await ShareLocal(c)(
      files,
      onFailure: (f, e, stackTrace) {
        if (e != null) {
          _log.shout(
              "[shareLocalFiles] Failed while sharing file: ${logFilename(f.logTag)}",
              e,
              stackTrace);
          if (!hasShownError) {
            SnackBarManager().showSnackBar(SnackBar(
              content: Text(exception_util.toUserString(e)),
              duration: k.snackBarDurationNormal,
            ));
            hasShownError = true;
          }
        }
      },
    );
  }

  Future<void> shareFiles(Account account, List<FileDescriptor> fds) async {
    final files = await InflateFileDescriptor(_c)(account, fds);
    try {
      final method = await _askShareMethod(files);
      if (method == null) {
        // user canceled
        return;
      } else if (method == ShareMethod.publicLink) {
        return await _shareAsLink(account, files, false);
      } else if (method == ShareMethod.passwordLink) {
        return await _shareAsLink(account, files, true);
      } else if (method == ShareMethod.preview) {
        return await _shareAsPreview(account, files);
      } else {
        return await _shareAsFile(account, files);
      }
    } catch (e, stackTrace) {
      _log.shout("[shareFiles] Failed while sharing files", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    } finally {
      if (!isSelectionCleared) {
        clearSelection?.call();
      }
    }
  }

  Future<ShareMethod?> _askShareMethod(List<File> files) {
    return showDialog<ShareMethod>(
      context: context,
      builder: (context) => ShareMethodDialog(
        isSupportPerview: files.any((f) => file_util.isSupportedImageFormat(f)),
      ),
    );
  }

  Future<void> _shareAsPreview(Account account, List<File> files) async {
    assert(platform_k.isAndroid);
    final controller = StreamController<String>();
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) => ProcessingDialog(
            text: L10n.global().shareDownloadingDialogContent +
                (snapshot.hasData ? " ${snapshot.data}" : ""),
          ),
        ),
      ),
    );
    final results = <Tuple2<File, dynamic>>[];
    for (final pair in files.withIndex()) {
      final i = pair.item1, f = pair.item2;
      controller.add("($i/${files.length})");
      try {
        final dynamic uri;
        if (file_util.isSupportedImageFormat(f) &&
            f.contentType != "image/gif") {
          uri = await DownloadPreview()(account, f);
        } else {
          uri = await DownloadFile()(account, f);
        }
        results.add(Tuple2(f, uri));
      } catch (e, stacktrace) {
        _log.shout(
            "[_shareAsPreview] Failed while DownloadPreview", e, stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    // dismiss the dialog
    Navigator.of(context).pop();

    final share = AndroidFileShare(
        results.map((e) => e.item2 as String).toList(),
        results.map((e) => e.item1.contentType).toList());
    return share.share();
  }

  Future<void> _shareAsFile(Account account, List<File> files) async {
    assert(platform_k.isAndroid);
    final controller = StreamController<String>();
    unawaited(
      showDialog(
        context: context,
        builder: (context) => StreamBuilder(
          stream: controller.stream,
          builder: (context, snapshot) => ProcessingDialog(
            text: L10n.global().shareDownloadingDialogContent +
                (snapshot.hasData ? " ${snapshot.data}" : ""),
          ),
        ),
      ),
    );
    final results = <Tuple2<File, dynamic>>[];
    for (final pair in files.withIndex()) {
      final i = pair.item1, f = pair.item2;
      controller.add("($i/${files.length})");
      try {
        results.add(Tuple2(
            f,
            await DownloadFile()(
              account,
              f,
              shouldNotify: false,
            )));
      } on PermissionException catch (_) {
        _log.warning("[_shareAsFile] Permission not granted");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().errorNoStoragePermission),
          duration: k.snackBarDurationNormal,
        ));
        // dismiss the dialog
        Navigator.of(context).pop();
        rethrow;
      } catch (e, stacktrace) {
        _log.shout("[_shareAsFile] Failed while downloadFile", e, stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    // dismiss the dialog
    Navigator.of(context).pop();

    final share = AndroidFileShare(
        results.map((e) => e.item2 as String).toList(),
        results.map((e) => e.item1.contentType).toList());
    return share.share();
  }

  Future<void> _shareAsLink(
      Account account, List<File> files, bool isPasswordProtected) async {
    if (files.length == 1) {
      String? password;
      if (isPasswordProtected) {
        password = await _askPassword();
        if (password == null) {
          // user canceled
          return;
        }
      }
      return _shareFileAsLink(account, files.first, password);
    } else {
      final result = await _askDirDetail(context, isPasswordProtected);
      if (result == null) {
        // user canceled
        return;
      }
      _log.info("[_shareAsLink] Share as folder: ${result.albumName}");
      SnackBarManager().showSnackBar(
        SnackBar(
          content: Text(L10n.global().createShareProgressText),
          duration: k.snackBarDurationShort,
        ),
        canBeReplaced: true,
      );
      clearSelection?.call();
      isSelectionCleared = true;

      final c = KiwiContainer().resolve<DiContainer>();
      final path = await _createDir(c.fileRepo, account, result.albumName);
      await _copyFilesToDir(c.fileRepo, account, files, path);
      return _shareFileAsLink(
        account,
        File(
          path: path,
          isCollection: true,
        ),
        result.password,
      );
    }
  }

  Future<void> _shareFileAsLink(
      Account account, File file, String? password) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    try {
      final share = await CreateLinkShare(shareRepo)(
        account,
        file,
        password: password,
      );
      await Clipboard.setData(ClipboardData(text: share.url));
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().linkCopiedNotification),
        duration: k.snackBarDurationNormal,
      ));

      if (platform_k.isAndroid) {
        final textShare = AndroidTextShare(share.url!);
        await textShare.share();
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_shareFileAsLink] Failed while CreateLinkShare", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<String?> _askPassword() {
    return showDialog<String>(
      context: context,
      builder: (context) => SimpleInputDialog(
        hintText: L10n.global().passwordInputHint,
        buttonText: MaterialLocalizations.of(context).okButtonLabel,
        validator: (value) {
          if (value?.isNotEmpty != true) {
            return L10n.global().passwordInputInvalidEmpty;
          }
          return null;
        },
        obscureText: true,
      ),
    );
  }

  Future<ShareLinkMultipleFilesDialogResult?> _askDirDetail(
      BuildContext context, bool isPasswordProtected) {
    return showDialog<ShareLinkMultipleFilesDialogResult>(
      context: context,
      builder: (_) => ShareLinkMultipleFilesDialog(
        shouldAskPassword: isPasswordProtected,
      ),
    );
  }

  Future<String> _createDir(
      FileRepo fileRepo, Account account, String name) async {
    // add a intermediate dir to allow shared dirs having the same name. Since
    // the dir names are public, we can't add random pre/suffix
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(0xFFFFFF);
    final dirName =
        "${timestamp.toRadixString(16)}-${random.toRadixString(16).padLeft(6, "0")}";
    final path =
        "${remote_storage_util.getRemoteLinkSharesDir(account)}/$dirName/$name";
    await CreateDir(fileRepo)(account, path);
    return path;
  }

  Future<void> _copyFilesToDir(FileRepo fileRepo, Account account,
      List<File> files, String dirPath) async {
    var failureCount = 0;
    for (final f in files) {
      try {
        await Copy(fileRepo)(account, f, "$dirPath/${f.filename}");
      } catch (e, stackTrace) {
        _log.severe(
            "[_copyFilesToDir] Failed while copying file: $f", e, stackTrace);
        ++failureCount;
      }
    }
    if (failureCount != 0) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().copyItemsFailureNotification(failureCount)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  final DiContainer _c;
  final BuildContext context;
  final VoidCallback? clearSelection;
  var isSelectionCleared = false;
}
