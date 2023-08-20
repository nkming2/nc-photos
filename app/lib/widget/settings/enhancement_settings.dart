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
import 'package:nc_photos/size.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/page_visibility_mixin.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_ui/np_ui.dart';
import 'package:to_string/to_string.dart';
import 'package:tuple/tuple.dart';

part 'enhancement/bloc.dart';
part 'enhancement/state_event.dart';
part 'enhancement_settings.g.dart';

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

class EnhancementSettings extends StatelessWidget {
  static const routeName = "/settings/enhancement";

  static Route buildRoute() => MaterialPageRoute(
        builder: (_) => const EnhancementSettings(),
      );

  const EnhancementSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        prefController: context.read(),
      ),
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
                    selector: (state) => state.isSaveEditResultToServer,
                    builder: (context, state) {
                      return SwitchListTile(
                        title: Text(L10n.global()
                            .settingsImageEditSaveResultsToServerTitle),
                        subtitle: Text(state
                            ? L10n.global()
                                .settingsImageEditSaveResultsToServerTrueDescription
                            : L10n.global()
                                .settingsImageEditSaveResultsToServerFalseDescription),
                        value: state,
                        onChanged: (value) {
                          _bloc.add(_SetSaveEditResultToServer(value));
                        },
                      );
                    },
                  ),
                  _BlocSelector<SizeInt>(
                    selector: (state) => state.maxSize,
                    builder: (context, state) {
                      return ListTile(
                        title: Text(
                            L10n.global().settingsEnhanceMaxResolutionTitle2),
                        subtitle: Text("${state.width}x${state.height}"),
                        onTap: () => _onMaxSizeTap(context, state),
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

  Future<void> _onMaxSizeTap(BuildContext context, SizeInt initialSize) async {
    var width = initialSize.width;
    var height = initialSize.height;
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(L10n.global().settingsEnhanceMaxResolutionTitle2),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.global().settingsEnhanceMaxResolutionDescription),
            const SizedBox(height: 16),
            _SizeSlider(
              initialWidth: initialSize.width,
              initialHeight: initialSize.height,
              onChanged: (value) {
                width = value.item1;
                height = value.item2;
              },
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
    if (!context.mounted ||
        result != true ||
        (width == initialSize.width && height == initialSize.height)) {
      return;
    }
    _bloc.add(_SetMaxSize(SizeInt(width, height)));
  }

  late final _bloc = context.read<_Bloc>();
}

class _SizeSlider extends StatefulWidget {
  const _SizeSlider({
    Key? key,
    required this.initialWidth,
    required this.initialHeight,
    this.onChanged,
  }) : super(key: key);

  @override
  createState() => _SizeSliderState();

  final int initialWidth;
  final int initialHeight;
  final ValueChanged<Tuple2<int, int>>? onChanged;
}

class _SizeSliderState extends State<_SizeSlider> {
  @override
  initState() {
    super.initState();
    _width = widget.initialWidth;
    _height = widget.initialHeight;
  }

  @override
  build(BuildContext context) {
    return Column(
      children: [
        Align(
          alignment: Alignment.center,
          child: Text("${_width}x$_height"),
        ),
        StatefulSlider(
          initialValue: resolutionToSliderValue(_width).toDouble(),
          min: -3,
          max: 3,
          divisions: 6,
          onChangeEnd: (value) async {
            final resolution = sliderValueToResolution(value.toInt());
            setState(() {
              _width = resolution.item1;
              _height = resolution.item2;
            });
            widget.onChanged?.call(resolution);
          },
        ),
      ],
    );
  }

  static Tuple2<int, int> sliderValueToResolution(int value) {
    switch (value) {
      case -3:
        return const Tuple2(1024, 768);
      case -2:
        return const Tuple2(1280, 960);
      case -1:
        return const Tuple2(1600, 1200);
      case 1:
        return const Tuple2(2560, 1920);
      case 2:
        return const Tuple2(3200, 2400);
      case 3:
        return const Tuple2(4096, 3072);
      default:
        return const Tuple2(2048, 1536);
    }
  }

  static int resolutionToSliderValue(int width) {
    switch (width) {
      case 1024:
        return -3;
      case 1280:
        return -2;
      case 1600:
        return -1;
      case 2560:
        return 1;
      case 3200:
        return 2;
      case 4096:
        return 3;
      default:
        return 0;
    }
  }

  late int _width;
  late int _height;
}
