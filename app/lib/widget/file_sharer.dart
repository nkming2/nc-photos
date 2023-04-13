import 'dart:async';
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_event.dart';
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
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:nc_photos/widget/share_link_multiple_files_dialog.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';
import 'package:tuple/tuple.dart';

part 'file_sharer.g.dart';
part 'file_sharer/bloc.dart';
part 'file_sharer/state_event.dart';
part 'file_sharer/type.dart';

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;

/// Dialog to let user share files with different options
///
/// Return true if the files are actually shared, false if user cancelled or
/// some errors occurred (e.g., missing permission)
class FileSharer extends StatelessWidget {
  const FileSharer({
    super.key,
    required this.account,
    required this.files,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(
        container: KiwiContainer().resolve(),
        account: account,
        files: files,
      ),
      child: const _WrappedFileSharer(),
    );
  }

  final Account account;
  final List<FileDescriptor> files;
}

class _WrappedFileSharer extends StatelessWidget {
  const _WrappedFileSharer();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) => previous.error != current.error,
          listener: (context, state) {
            if (state.error != null) {
              if (state.error!.error is PermissionException) {
                SnackBarManager().showSnackBar(SnackBar(
                  content: Text(L10n.global().errorNoStoragePermission),
                  duration: k.snackBarDurationNormal,
                ));
              } else {
                SnackBarManager().showSnackBar(SnackBar(
                  content:
                      Text(exception_util.toUserString(state.error!.error)),
                  duration: k.snackBarDurationNormal,
                ));
              }
            }
          },
        ),
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) =>
              previous.message != current.message,
          listener: (context, state) {
            if (state.message != null) {
              SnackBarManager().showSnackBar(SnackBar(
                content: Text(state.message!),
                duration: k.snackBarDurationNormal,
              ));
            }
          },
        ),
        BlocListener<_Bloc, _State>(
          listenWhen: (previous, current) => previous.result != current.result,
          listener: (context, state) {
            if (state.result != null) {
              Navigator.of(context).pop(state.result);
            }
          },
        ),
      ],
      child: _BlocBuilder(
        buildWhen: (previous, current) => previous.method != current.method,
        builder: (context, state) {
          switch (state.method) {
            case null:
              return const _ShareMethodDialog();
            case ShareMethod.file:
              return const _ShareFileDialog();
            case ShareMethod.preview:
              return const _SharePreviewDialog();
            case ShareMethod.publicLink:
              return const _SharePublicLinkDialog();
            case ShareMethod.passwordLink:
              return const _SharePasswordLinkDialog();
          }
        },
      ),
    );
  }
}

class _ShareMethodDialog extends StatelessWidget {
  const _ShareMethodDialog();

  @override
  Widget build(BuildContext context) {
    final isSupportPerview = context
        .read<_Bloc>()
        .files
        .any((f) => file_util.isSupportedImageFormat(f));
    return SimpleDialog(
      title: Text(L10n.global().shareMethodDialogTitle),
      children: [
        if (platform_k.isAndroid) ...[
          if (isSupportPerview)
            SimpleDialogOption(
              child: ListTile(
                title: Text(L10n.global().shareMethodPreviewTitle),
                subtitle: Text(L10n.global().shareMethodPreviewDescription),
              ),
              onPressed: () {
                context
                    .read<_Bloc>()
                    .add(const _SetMethod(ShareMethod.preview));
              },
            ),
          SimpleDialogOption(
            child: ListTile(
              title: Text(L10n.global().shareMethodOriginalFileTitle),
              subtitle: Text(L10n.global().shareMethodOriginalFileDescription),
            ),
            onPressed: () {
              context.read<_Bloc>().add(const _SetMethod(ShareMethod.file));
            },
          ),
        ],
        SimpleDialogOption(
          child: ListTile(
            title: Text(L10n.global().shareMethodPublicLinkTitle),
            subtitle: Text(L10n.global().shareMethodPublicLinkDescription),
          ),
          onPressed: () {
            context.read<_Bloc>().add(const _SetMethod(ShareMethod.publicLink));
          },
        ),
        SimpleDialogOption(
          child: ListTile(
            title: Text(L10n.global().shareMethodPasswordLinkTitle),
            subtitle: Text(L10n.global().shareMethodPasswordLinkDescription),
          ),
          onPressed: () {
            context
                .read<_Bloc>()
                .add(const _SetMethod(ShareMethod.passwordLink));
          },
        ),
      ],
    );
  }
}

class _ShareFileDialog extends StatelessWidget {
  const _ShareFileDialog();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.previewState?.index != current.previewState?.index ||
          previous.previewState?.count != current.previewState?.count,
      builder: (context, state) {
        final text = state.previewState?.index != null &&
                state.previewState?.count != null
            ? " (${state.previewState!.index}/${state.previewState!.count})"
            : "";
        return ProcessingDialog(
          text: L10n.global().shareDownloadingDialogContent + text,
        );
      },
    );
  }
}

class _SharePreviewDialog extends StatelessWidget {
  const _SharePreviewDialog();

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.previewState?.index != current.previewState?.index ||
          previous.previewState?.count != current.previewState?.count,
      builder: (context, state) {
        final text = state.previewState?.index != null &&
                state.previewState?.count != null
            ? " (${state.previewState!.index}/${state.previewState!.count})"
            : "";
        return ProcessingDialog(
          text: L10n.global().shareDownloadingDialogContent + text,
        );
      },
    );
  }
}

class _SharePublicLinkDialog extends StatefulWidget {
  const _SharePublicLinkDialog();

  @override
  State<StatefulWidget> createState() => _SharePublicLinkDialogState();
}

class _SharePublicLinkDialogState extends State<_SharePublicLinkDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askDetails());
  }

  @override
  Widget build(BuildContext context) {
    return ProcessingDialog(text: L10n.global().createShareProgressText);
  }

  Future<void> _askDetails() async {
    if (_bloc.files.length == 1) {
      _bloc.add(const _SetPublicLinkDetails());
    } else {
      final result = await showDialog<ShareLinkMultipleFilesDialogResult>(
        context: context,
        builder: (context) => const ShareLinkMultipleFilesDialog(
          shouldAskPassword: false,
        ),
      );
      if (!mounted) {
        return;
      }
      if (result == null) {
        _bloc.add(const _SetResult(false));
        return;
      } else {
        _bloc.add(_SetPublicLinkDetails(
          albumName: result.albumName,
        ));
      }
    }
  }

  late final _bloc = context.read<_Bloc>();
}

class _SharePasswordLinkDialog extends StatefulWidget {
  const _SharePasswordLinkDialog();

  @override
  State<StatefulWidget> createState() => _SharePasswordLinkDialogState();
}

class _SharePasswordLinkDialogState extends State<_SharePasswordLinkDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _askDetails());
  }

  @override
  Widget build(BuildContext context) {
    return _BlocBuilder(
      buildWhen: (previous, current) =>
          previous.passwordLinkState?.password !=
          current.passwordLinkState?.password,
      builder: (context, state) {
        if (state.passwordLinkState?.password == null) {
          return Container();
        } else {
          return ProcessingDialog(text: L10n.global().createShareProgressText);
        }
      },
    );
  }

  Future<void> _askDetails() async {
    if (_bloc.files.length == 1) {
      final result = await showDialog<String>(
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
      if (!mounted) {
        return;
      }
      if (result == null) {
        _bloc.add(const _SetResult(false));
        return;
      } else {
        _bloc.add(_SetPasswordLinkDetails(password: result));
      }
    } else {
      final result = await showDialog<ShareLinkMultipleFilesDialogResult>(
        context: context,
        builder: (context) => const ShareLinkMultipleFilesDialog(
          shouldAskPassword: true,
        ),
      );
      if (!mounted) {
        return;
      }
      if (result == null) {
        _bloc.add(const _SetResult(false));
        return;
      } else {
        _bloc.add(_SetPasswordLinkDetails(
          albumName: result.albumName,
          password: result.password!,
        ));
      }
    }
  }

  late final _bloc = context.read<_Bloc>();
}
