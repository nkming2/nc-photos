import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/disposable.dart';
import 'package:nc_photos/widget/horizontal_page_viewer.dart';
import 'package:nc_photos/widget/image_viewer.dart';
import 'package:nc_photos/widget/slideshow_dialog.dart';
import 'package:nc_photos/widget/video_viewer.dart';
import 'package:nc_photos/widget/viewer_mixin.dart';
import 'package:nc_photos/widget/wakelock_util.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_ui/np_ui.dart';
import 'package:to_string/to_string.dart';

part 'slideshow_viewer.g.dart';
part 'slideshow_viewer/bloc.dart';
part 'slideshow_viewer/state_event.dart';
part 'slideshow_viewer/view.dart';

class SlideshowViewerArguments {
  const SlideshowViewerArguments(
    this.account,
    this.files,
    this.startIndex,
    this.config,
  );

  final Account account;
  final List<FileDescriptor> files;
  final int startIndex;
  final SlideshowConfig config;
}

class SlideshowViewer extends StatelessWidget {
  static const routeName = "/slideshow-viewer";

  static Route buildRoute(SlideshowViewerArguments args) => MaterialPageRoute(
        builder: (context) => SlideshowViewer.fromArgs(args),
      );

  const SlideshowViewer({
    super.key,
    required this.account,
    required this.files,
    required this.startIndex,
    required this.config,
  });

  SlideshowViewer.fromArgs(SlideshowViewerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          files: args.files,
          startIndex: args.startIndex,
          config: args.config,
        );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _Bloc(
        account: context.read<AccountController>().account,
        files: files,
        startIndex: startIndex,
        config: config,
      )..add(const _Init()),
      child: const _WrappedSlideshowViewer(),
    );
  }

  final Account account;
  final List<FileDescriptor> files;
  final int startIndex;
  final SlideshowConfig config;
}

class _WrappedSlideshowViewer extends StatefulWidget {
  const _WrappedSlideshowViewer();

  @override
  State<StatefulWidget> createState() => _WrappedSlideshowViewerState();
}

class _WrappedSlideshowViewerState extends State<_WrappedSlideshowViewer>
    with
        DisposableManagerMixin<_WrappedSlideshowViewer>,
        ViewerControllersMixin<_WrappedSlideshowViewer> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  }

  @override
  List<Disposable> initDisposables() {
    return [
      ...super.initDisposables(),
      WakelockControllerDisposable(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDarkTheme(context),
      child: const Scaffold(
        body: _Body(),
      ),
    );
  }
}

// typedef _BlocBuilder = BlocBuilder<_Bloc, _State>;
// typedef _BlocListener = BlocListener<_Bloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_Bloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_Bloc, _State, T>;

extension on BuildContext {
  _Bloc get bloc => read<_Bloc>();
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
