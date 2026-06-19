import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/any_file/any_file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/local_file.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/ls_single_file.dart';
import 'package:nc_photos/widget/anyfile_list_viewer/anyfile_list_viewer.dart';
import 'package:np_log/np_log.dart';
import 'package:to_string/to_string.dart';

part 'bloc.dart';
part 'enhance_result_viewer.g.dart';
part 'state_event.dart';

class EnhanceResultViewerArguments {
  const EnhanceResultViewerArguments({required this.persistResult});

  final String persistResult;
}

class EnhanceResultViewer extends StatelessWidget {
  static const routeName = "/enhance-result-viewer";

  static Route buildRoute(
    EnhanceResultViewerArguments args,
    RouteSettings settings,
  ) => MaterialPageRoute(
    builder: (_) => EnhanceResultViewer.fromArgs(args),
    settings: settings,
  );

  const EnhanceResultViewer({super.key, required this.persistResult});

  EnhanceResultViewer.fromArgs(EnhanceResultViewerArguments args, {Key? key})
    : this(key: key, persistResult: args.persistResult);

  @override
  Widget build(BuildContext context) {
    final accountController = context.read<AccountController>();
    return BlocProvider(
      create: (_) => _Bloc(
        c: KiwiContainer().resolve<DiContainer>(),
        account: accountController.account,
        persistResult: persistResult,
      ),
      child: const _WrappedEnhanceResultViewer(),
    );
  }

  final String persistResult;
}

class _WrappedEnhanceResultViewer extends StatelessWidget {
  const _WrappedEnhanceResultViewer();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        _BlocListenerT(
          selector: (state) => state.error,
          listener: (context, error) {
            if (error != null) {
              SnackBarManager().showSnackBarForException(error.error);
              Navigator.of(context).pop();
            }
          },
        ),
      ],
      child: _BlocSelector(
        selector: (state) => state.file,
        builder: (context, anyFile) {
          if (anyFile != null) {
            return AnyFileListViewer(files: [anyFile], initialIndex: 0);
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;
typedef _Emitter = Emitter<_State>;

extension on BuildContext {
  // _Bloc get bloc => read<_Bloc>();
  // _State get state => bloc.state;
  // void addEvent(_Event event) => bloc.add(event);
}
