import 'dart:async';
import 'dart:ui';

import 'package:clock/clock.dart';
import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/controller/pref_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/collection/content_provider/ad_hoc.dart';
import 'package:nc_photos/entity/image_location/repo.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/stream_extension.dart';
import 'package:nc_photos/stream_util.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/theme/dimension.dart';
import 'package:nc_photos/widget/collection_browser.dart';
import 'package:nc_photos/widget/measure.dart';
import 'package:nc_photos/widget/navigation_bar_blur_filter.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_common/object_util.dart';
import 'package:np_datetime/np_datetime.dart';
import 'package:np_gps_map/np_gps_map.dart';
import 'package:to_string/to_string.dart';

part 'map_browser.g.dart';
part 'map_browser/bloc.dart';
part 'map_browser/state_event.dart';
part 'map_browser/type.dart';
part 'map_browser/view.dart';

class MapBrowser extends StatelessWidget {
  const MapBrowser({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => _Bloc(
        KiwiContainer().resolve(),
        account: context.read<AccountController>().account,
        prefController: context.read(),
      )..add(const _LoadData()),
      child: const _WrappedMapBrowser(),
    );
  }
}

class _WrappedMapBrowser extends StatelessWidget {
  const _WrappedMapBrowser();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
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
      child: Stack(
        children: [
          const _MapView(),
          Positioned.directional(
            textDirection: Directionality.of(context),
            top: MediaQuery.of(context).padding.top + 8,
            end: 8,
            child: const _DateRangeToggle(),
          ),
          _BlocSelector<bool>(
            selector: (state) => state.isShowDataRangeControlPanel,
            builder: (context, isShowAnyPanel) => Positioned.fill(
              child: isShowAnyPanel
                  ? GestureDetector(
                      onTap: () {
                        context.addEvent(const _CloseControlPanel());
                      },
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            top: MediaQuery.of(context).padding.top + 8,
            child: _BlocSelector<bool>(
              selector: (state) => state.isShowDataRangeControlPanel,
              builder: (context, isShowDataRangeControlPanel) =>
                  _PanelContainer(
                isShow: isShowDataRangeControlPanel,
                child: const _DateRangeControlPanel(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: NavigationBarBlurFilter(
              height: AppDimension.of(context).homeBottomAppBarHeight,
            ),
          ),
        ],
      ),
    );
  }
}

typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
