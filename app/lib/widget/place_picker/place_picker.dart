import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/stream_util.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_gps_map/np_gps_map.dart';
import 'package:to_string/to_string.dart';

part 'bloc.dart';
part 'place_picker.g.dart';
part 'state_event.dart';

class PlacePicker extends StatelessWidget {
  static const routeName = "/place-picker";

  static Route buildRoute(RouteSettings settings) =>
      MaterialPageRoute<CameraPosition>(
        builder: (_) => const PlacePicker(),
        settings: settings,
      );

  const PlacePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(),
      child: const _WrappedPlacePicker(),
    );
  }
}

@npLog
class _WrappedPlacePicker extends StatelessWidget {
  const _WrappedPlacePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.global().placePickerTitle),
        leading: IconButton(
          onPressed: () {
            final position = context.state.position;
            _log.info("[build] Position picked: $position");
            Navigator.of(context).pop(position);
          },
          icon: const Icon(Icons.check_outlined),
        ),
      ),
      body: const _BodyView(),
    );
  }
}

class _BodyView extends StatelessWidget {
  const _BodyView();

  @override
  Widget build(BuildContext context) {
    final prevPosition =
        context.read<PrefController>().mapBrowserPrevPositionValue;
    return ValueStreamBuilderEx<GpsMapProvider>(
      stream: context.read<PrefController>().gpsMapProvider,
      builder: StreamWidgetBuilder.value(
        (context, gpsMapProvider) => PlacePickerView(
          providerHint: gpsMapProvider,
          initialPosition: prevPosition ?? const MapCoord(0, 0),
          initialZoom: prevPosition == null ? 2.5 : 10,
          onCameraMove: (position) {
            context.addEvent(_SetPosition(position));
          },
        ),
      ),
    );
  }
}

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
// typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
// typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;
typedef _Emitter = Emitter<_State>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
