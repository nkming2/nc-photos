import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/controller/account_pref_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/home.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:nc_photos/widget/root_picker.dart';
import 'package:nc_photos/widget/settings/settings_list_caption.dart';
import 'package:nc_photos/widget/share_folder_picker.dart';
import 'package:nc_photos/widget/simple_input_dialog.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'account/bloc.dart';
part 'account/state_event.dart';
part 'account_settings.g.dart';

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

class AccountSettings extends StatelessWidget {
  static const routeName = "/account-settings";

  static Route buildRoute() => MaterialPageRoute(
        builder: (_) => const AccountSettings(),
      );

  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final accountController = context.read<AccountController>();
    return BlocProvider(
      create: (_) => _Bloc(
        container: KiwiContainer().resolve(),
        account: accountController.account,
        accountPrefController: accountController.accountPrefController,
      ),
      child: const _WrappedAccountSettings(),
    );
  }
}

class _WrappedAccountSettings extends StatefulWidget {
  const _WrappedAccountSettings();

  @override
  State<StatefulWidget> createState() => _WrappedDeveloperSettingsState();
}

@npLog
class _WrappedDeveloperSettingsState extends State<_WrappedAccountSettings>
    with RouteAware, PageVisibilityMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          _BlocListener(
            listenWhen: (previous, current) => previous.error != current.error,
            listener: (context, state) {
              if (state.error != null && isPageVisible()) {
                final String errorMsg;
                if (state.error is _AccountConflictError) {
                  errorMsg =
                      L10n.global().editAccountConflictFailureNotification;
                } else if (state.error is _WritePrefError) {
                  errorMsg = L10n.global().writePreferenceFailureNotification;
                } else {
                  errorMsg = exception_util.toUserString(state.error!.error);
                }
                SnackBarManager().showSnackBar(SnackBar(
                  content: Text(errorMsg),
                  duration: k.snackBarDurationNormal,
                ));
              }
            },
          ),
        ],
        child: WillPopScope(
          onWillPop: () async => !context.read<_Bloc>().state.shouldReload,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                title: Text(L10n.global().settingsAccountTitle),
                leading: _BlocSelector<bool>(
                  selector: (state) => state.shouldReload,
                  builder: (_, state) =>
                      state ? const _DoneButton() : const BackButton(),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _BlocSelector<String?>(
                      selector: (state) => state.label,
                      builder: (context, state) => ListTile(
                        title: Text(L10n.global().settingsAccountLabelTitle),
                        subtitle: Text(state ??
                            L10n.global().settingsAccountLabelDescription),
                        onTap: () => _onLabelPressed(context),
                      ),
                    ),
                    _BlocSelector<Account>(
                      selector: (state) => state.account,
                      builder: (context, state) => ListTile(
                        title: Text(L10n.global().settingsIncludedFoldersTitle),
                        subtitle:
                            Text(state.roots.map((e) => "/$e").join("; ")),
                        onTap: () => _onIncludedFoldersPressed(context),
                      ),
                    ),
                    _BlocSelector<String>(
                      selector: (state) => state.shareFolder,
                      builder: (context, state) => ListTile(
                        title: Text(L10n.global().settingsShareFolderTitle),
                        subtitle: Text("/$state"),
                        onTap: () => _onShareFolderPressed(context),
                      ),
                    ),
                    SettingsListCaption(
                      label: L10n.global().settingsServerAppSectionTitle,
                    ),
                    _BlocSelector<bool>(
                      selector: (state) => state.isEnableFaceRecognitionApp,
                      builder: (context, state) => SwitchListTile(
                        title: const Text("Face Recognition"),
                        value: state,
                        onChanged: (value) =>
                            _onEnableFaceRecognitionAppChanged(context, value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLabelPressed(BuildContext context) async {
    final bloc = context.read<_Bloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleInputDialog(
        titleText: L10n.global().settingsAccountLabelTitle,
        buttonText: MaterialLocalizations.of(context).okButtonLabel,
        initialText: bloc.state.label ?? "",
      ),
    );
    if (!context.mounted || result == null) {
      return;
    }
    context.read<_Bloc>().add(_SetLabel(result.isEmpty ? null : result));
  }

  Future<void> _onIncludedFoldersPressed(BuildContext context) async {
    final bloc = context.read<_Bloc>();
    final result = await Navigator.of(context).pushNamed<Account>(
      RootPicker.routeName,
      arguments: RootPickerArguments(bloc.state.account),
    );
    if (result == null) {
      return;
    }
    if (result == bloc.state.account) {
      // no changes, do nothing
      _log.fine("[_onIncludedFoldersPressed] No changes");
      return;
    }
    context.read<_Bloc>().add(_SetAccount(result));
  }

  Future<void> _onShareFolderPressed(BuildContext context) async {
    final bloc = context.read<_Bloc>();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ShareFolderDialog(
        account: bloc.state.account,
        initialValue: bloc.state.shareFolder,
      ),
    );
    if (!context.mounted || result == null) {
      return;
    }
    context.read<_Bloc>().add(_SetShareFolder(result));
  }

  void _onEnableFaceRecognitionAppChanged(BuildContext context, bool value) {
    context.read<_Bloc>().add(_SetEnableFaceRecognitionApp(value));
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.check),
      tooltip: L10n.global().doneButtonTooltip,
      onPressed: () {
        final newAccount = context.read<_Bloc>().state.account;
        context.read<AccountController>().setCurrentAccount(newAccount);
        Navigator.of(context).pushNamedAndRemoveUntil(
          Home.routeName,
          (_) => false,
          arguments: HomeArguments(newAccount),
        );
      },
    );
  }
}

class _ShareFolderDialog extends StatefulWidget {
  const _ShareFolderDialog({
    required this.account,
    required this.initialValue,
  });

  @override
  State<StatefulWidget> createState() => _ShareFolderDialogState();

  final Account account;
  final String initialValue;
}

class _ShareFolderDialogState extends State<_ShareFolderDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().settingsShareFolderDialogTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.global().settingsShareFolderDialogDescription),
            const SizedBox(height: 8),
            InkWell(
              onTap: _onTextFieldPressed,
              child: TextFormField(
                enabled: false,
                controller: _controller,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _onOkPressed,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  Future<void> _onTextFieldPressed() async {
    final pick = await Navigator.of(context).pushNamed<String>(
      ShareFolderPicker.routeName,
      arguments: ShareFolderPickerArguments(widget.account, _path),
    );
    if (pick != null) {
      _path = pick;
      _controller.text = "/$pick";
    }
  }

  void _onOkPressed() {
    Navigator.of(context).pop(_path);
  }

  final _formKey = GlobalKey<FormState>();
  late final _controller =
      TextEditingController(text: "/${widget.initialValue}");
  late String _path = widget.initialValue;
}
