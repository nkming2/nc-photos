import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:np_log/np_log.dart';
import 'package:np_ui/np_ui.dart';
import 'package:to_string/to_string.dart';

part 'enhancement/bloc.dart';
part 'enhancement/state_event.dart';
part 'enhancement_settings.g.dart';

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

class EnhancementSettings extends StatelessWidget {
  static const routeName = "/settings/enhancement";

  static Route buildRoute(RouteSettings settings) => MaterialPageRoute(
    builder: (_) => const EnhancementSettings(),
    settings: settings,
  );

  const EnhancementSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(prefController: context.read()),
      child: const _WrappedEnhancementSettings(),
    );
  }
}

class _WrappedEnhancementSettings extends StatefulWidget {
  const _WrappedEnhancementSettings();

  @override
  State<StatefulWidget> createState() => _WrappedEnhancementSettingsState();
}

class _WrappedEnhancementSettingsState
    extends State<_WrappedEnhancementSettings>
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
                SnackBarManager().showSnackBarForException(state.error!.error);
              }
            },
          ),
        ],
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              title: Text(L10n.global().settingsImageEditTitle),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                _BlocSelector<bool>(
                  selector: (state) => state.isSaveEditResultToServer,
                  builder: (context, state) {
                    return SwitchListTile(
                      title: Text(
                        L10n.global().settingsImageEditSaveResultsToServerTitle,
                      ),
                      subtitle: Text(
                        state
                            ? L10n.global()
                                  .settingsImageEditSaveResultsToServerTrueDescription
                            : L10n.global()
                                  .settingsImageEditSaveResultsToServerFalseDescription,
                      ),
                      value: state,
                      onChanged: (value) {
                        _bloc.add(_SetSaveEditResultToServer(value));
                      },
                    );
                  },
                ),
              ]),
            ),
            const SliverSafeBottom(),
          ],
        ),
      ),
    );
  }

  late final _bloc = context.read<_Bloc>();
}
