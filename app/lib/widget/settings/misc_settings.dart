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
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'misc/bloc.dart';
part 'misc/state_event.dart';
part 'misc_settings.g.dart';

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

class MiscSettings extends StatelessWidget {
  const MiscSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        prefController: context.read(),
      ),
      child: const _WrappedMiscSettings(),
    );
  }
}

class _WrappedMiscSettings extends StatefulWidget {
  const _WrappedMiscSettings();

  @override
  State<StatefulWidget> createState() => _WrappedMiscSettingsState();
}

class _WrappedMiscSettingsState extends State<_WrappedMiscSettings>
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
              title: Text(L10n.global().photosTabLabel),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                [
                  _BlocSelector<bool>(
                    selector: (state) => state.isDoubleTapExit,
                    builder: (_, state) {
                      return SwitchListTile(
                        title: Text(L10n.global().settingsDoubleTapExitTitle),
                        value: state,
                        onChanged: (value) {
                          _bloc.add(_SetDoubleTapExit(value));
                        },
                      );
                    },
                  ),
                  _BlocSelector<bool>(
                    selector: (state) => state.isPhotosTabSortByName,
                    builder: (_, state) {
                      return SwitchListTile(
                        title: Text(
                            L10n.global().settingsPhotosTabSortByNameTitle),
                        value: state,
                        onChanged: (value) {
                          _bloc.add(_SetPhotosTabSortByName(value));
                        },
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

  late final _bloc = context.read<_Bloc>();
}
