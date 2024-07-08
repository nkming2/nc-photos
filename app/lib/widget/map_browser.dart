import 'dart:async';
import 'dart:ui';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/content_provider/ad_hoc.dart';
import 'package:nc_photos/entity/image_location/repo.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/collection_browser.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:to_string/to_string.dart';

part 'map_browser.g.dart';
part 'map_browser/bloc.dart';
part 'map_browser/state_event.dart';
part 'map_browser/type.dart';
part 'map_browser/view.dart';

class MapBrowser extends StatelessWidget {
  static const routeName = "/map-browser";

  static Route buildRoute() => MaterialPageRoute(
        builder: (_) => const MapBrowser(),
      );

  const MapBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        KiwiContainer().resolve(),
        account: context.read<AccountController>().account,
      )..add(const _Init()),
      child: const _WrappedMapBrowser(),
    );
  }
}

class _WrappedMapBrowser extends StatelessWidget {
  const _WrappedMapBrowser();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: MultiBlocListener(
          listeners: [
            _BlocListenerT<ExceptionEvent?>(
              selector: (state) => state.error,
              listener: (context, error) {
                if (error != null) {
                  SnackBarManager().showSnackBarForException(error.error);
                }
              },
            ),
          ],
          child: const _MapView(),
        ),
      ),
    );
  }
}

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
// typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
