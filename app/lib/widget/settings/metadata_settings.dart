import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/service.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'metadata/bloc.dart';
part 'metadata/state_event.dart';
part 'metadata_settings.g.dart';

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

class MetadataSettings extends StatelessWidget {
  const MetadataSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        prefController: context.read(),
      ),
      child: const _WrappedMetadataSettings(),
    );
  }
}

class _WrappedMetadataSettings extends StatefulWidget {
  const _WrappedMetadataSettings();

  @override
  State<StatefulWidget> createState() => _WrappedMetadataSettingsState();
}

class _WrappedMetadataSettingsState extends State<_WrappedMetadataSettings>
    with RouteAware, PageVisibilityMixin {
  @override
  void initState() {
    super.initState();
    _bloc.add(const _Init());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: [
          _BlocListener(
            listenWhen: (previous, current) => previous.error != current.error,
            listener: (context, state) {
              if (state.error != null && isPageVisible()) {
                SnackBarManager().showSnackBar(SnackBar(
                  content:
                      Text(exception_util.toUserString(state.error!.error)),
                  duration: k.snackBarDurationNormal,
                ));
              }
            },
          ),
        ],
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(L10n.global().settingsMetadataTitle),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  _BlocSelector<bool>(
                    selector: (state) => state.isEnable,
                    builder: (context, state) {
                      return SwitchListTile(
                        title: Text(L10n.global().settingsExifSupportTitle),
                        subtitle: state
                            ? Text(
                                L10n.global().settingsExifSupportTrueSubtitle)
                            : null,
                        value: state,
                        onChanged: (value) => _onEnableChanged(context, value),
                      );
                    },
                  ),
                  if (platform_k.isMobile)
                    _BlocBuilder(
                      buildWhen: (previous, current) =>
                          previous.isEnable != current.isEnable ||
                          previous.isWifiOnly != current.isWifiOnly,
                      builder: (context, state) {
                        return SwitchListTile(
                          title: Text(L10n.global().settingsExifWifiOnlyTitle),
                          subtitle: state.isWifiOnly
                              ? null
                              : Text(L10n.global()
                                  .settingsExifWifiOnlyFalseSubtitle),
                          value: state.isWifiOnly,
                          onChanged: state.isEnable
                              ? (value) {
                                  _bloc.add(_SetWifiOnly(value));
                                }
                              : null,
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onEnableChanged(BuildContext context, bool value) async {
    if (value) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(L10n.global().exifSupportConfirmationDialogTitle),
          content: Text(L10n.global().exifSupportDetails),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(L10n.global().enableButtonLabel),
            ),
          ],
        ),
      );
      if (context.mounted && result == true) {
        _bloc.add(const _SetEnable(true));
      }
    } else {
      _bloc.add(const _SetEnable(false));
    }
  }

  late final _bloc = context.read<_Bloc>();
}
