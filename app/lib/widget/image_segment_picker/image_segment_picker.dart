import 'dart:async';
import 'dart:math';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:copy_with/copy_with.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/entity/any_file/any_file.dart';
import 'package:nc_photos/entity/any_file/content/factory.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/app_bar_circular_progress_indicator.dart';
import 'package:nc_photos/widget/file_content_view/file_content_view.dart';
import 'package:nc_photos/widget/zoomable_viewer.dart';
import 'package:np_collection/np_collection.dart';
import 'package:np_common/unique.dart';
import 'package:np_ffi_torch/np_ffi_torch.dart';
import 'package:np_log/np_log.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';
import 'package:np_ui/np_ui.dart';
import 'package:to_string/to_string.dart';

part 'bloc.dart';
part 'image_segment_picker.g.dart';
part 'shimmer.dart';
part 'state_event.dart';

class ImageSegmentPickerArguments {
  const ImageSegmentPickerArguments({required this.file});

  final AnyFile file;
}

class ImageSegmentPicker extends StatelessWidget {
  static const routeName = "/image-segment-picker";

  static Route buildRoute(
    ImageSegmentPickerArguments args,
    RouteSettings settings,
  ) => MaterialPageRoute<Rgba8Image>(
    builder: (_) => ImageSegmentPicker.fromArgs(args),
    settings: settings,
  );

  const ImageSegmentPicker({super.key, required this.file});

  ImageSegmentPicker.fromArgs(ImageSegmentPickerArguments args, {Key? key})
    : this(key: key, file: args.file);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDarkTheme(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: BlocProvider(
          create: (context) => _IspBloc(
            account: context.read<AccountController>().account,
            file: file,
          )..add(const _Init()),
          child: const _WrappedImageSegmentPicker(),
        ),
      ),
    );
  }

  final AnyFile file;
}

class _WrappedImageSegmentPicker extends StatelessWidget {
  const _WrappedImageSegmentPicker();

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        _BlocListenerT(
          selector: (state) => state.maxPointPromptsReached,
          listener: (context, maxPointPromptsReached) {
            if (maxPointPromptsReached.value) {
              SnackBarManager().showSnackBar(
                SnackBar(
                  content: Text(L10n.global().imageSegmentPicker6PointLimit),
                  duration: k.snackBarDurationNormal,
                ),
              );
            }
          },
        ),
        _BlocListenerT(
          selector: (state) => state.initError,
          listener: (context, initError) {
            if (initError != null) {
              SnackBarManager().showSnackBar(
                SnackBar(
                  content: Text(
                    L10n.global().imageSegmentPickerInitFailedText +
                        " (${exception_util.toUserString(initError.error)})",
                  ),
                  duration: k.snackBarDurationNormal,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            _BlocBuilder(
              buildWhen: (previous, current) =>
                  previous.extractionResult != current.extractionResult ||
                  previous.isLoading != current.isLoading,
              builder: (context, state) {
                if (state.extractionResult == null) {
                  return const SizedBox.shrink();
                } else if (state.isLoading) {
                  return const IconButton(
                    onPressed: null,
                    icon: AppBarProgressIndicator(),
                  );
                } else {
                  return TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(state.extractionResult!);
                    },
                    child: Text(L10n.global().confirmButtonLabel),
                  );
                }
              },
            ),
          ],
        ),
        body: _BlocBuilder(
          buildWhen: (previous, current) =>
              previous.isReady != current.isReady ||
              previous.initError != current.initError,
          builder: (context, state) {
            if (state.isReady == null) {
              return const SizedBox.shrink();
            } else if (!state.isReady!) {
              if (state.initError != null) {
                return const _DownloadErrorView();
              } else {
                return const _DownloadProgressView();
              }
            } else {
              return const _SegmenterView();
            }
          },
        ),
      ),
    );
  }
}

class _DownloadErrorView extends StatelessWidget {
  const _DownloadErrorView();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _BlocBuilder(
        buildWhen: (previous, current) =>
            previous.downloadProgress != current.downloadProgress ||
            previous.downloadSize != current.downloadSize,
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sick_outlined, size: 48),
            const SizedBox(height: 8),
            Text(
              L10n.global().imageSegmentPickerInitFailedText,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadProgressView extends StatefulWidget {
  const _DownloadProgressView();

  @override
  State<_DownloadProgressView> createState() => _DownloadProgressViewState();
}

class _DownloadProgressViewState extends State<_DownloadProgressView>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: _BlocBuilder(
        buildWhen: (previous, current) =>
            previous.downloadProgress != current.downloadProgress ||
            previous.downloadSize != current.downloadSize,
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotationTransition(
              turns: _animController,
              child: const Icon(Icons.settings_outlined, size: 48),
            ),
            const SizedBox(height: 8),
            Text(
              L10n.global().imageEnhancerModelDownloadDialogText,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.downloadProgress),
            if (state.downloadSize != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: Text(
                  _getSizeText(state.downloadSize!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getSizeText(int size) {
    if (size < 1024) {
      return "${size}B";
    } else if (size < 1024 * 1024) {
      return "${(size / 1024).toStringAsFixed(1)}KB";
    } else {
      return "${(size / 1024 / 1024).toStringAsFixed(1)}MB";
    }
  }

  late final AnimationController _animController;
}

class _SegmenterView extends StatelessWidget {
  const _SegmenterView();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ZoomableViewer(
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            alignment: Alignment.center,
            child: FileContentView(
              file: context.bloc.file,
              shouldPlayLivePhoto: false,
              canZoom: true,
              canPlay: false,
              isPlayControlVisible: false,
              onTapAt: (position) {
                context.addEvent(_NewPointPrompt(position));
              },
              frameBuilder: (context, child) {
                return _BlocBuilder(
                  buildWhen: (previous, current) =>
                      previous.extractionResult != current.extractionResult ||
                      previous.pointPrompts != current.pointPrompts,
                  builder: (context, state) => Stack(
                    children: [
                      Opacity(
                        opacity: state.extractionResult == null ? 1 : .25,
                        child: child,
                      ),
                      if (state.extractionResult != null)
                        Image(
                          key: Key(
                            "extractionResult-${identityHashCode(state.extractionResult)}",
                          ),
                          image: PixelImage(
                            state.extractionResult!.pixel,
                            state.extractionResult!.width,
                            state.extractionResult!.height,
                          ),
                          filterQuality: FilterQuality.high,
                          fit: BoxFit.contain,
                          gaplessPlayback: true,
                        ),
                      ...state.pointPrompts.map(
                        (e) => Align(
                          alignment: Alignment(e.x * 2 - 1, e.y * 2 - 1),
                          child: Transform.translate(
                            offset: Offset(
                              _PointPromptMarker.size / 2 * (e.x * 2 - 1),
                              _PointPromptMarker.size / 2 * (e.y * 2 - 1),
                            ),
                            child: AnimatedEnterOpacity(
                              duration: const Duration(milliseconds: 350),
                              curve: Curves.easeOut,
                              child: _PointPromptMarker(key: ValueKey(e)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        _BlocSelector(
          selector: (state) => state.isLoading,
          builder: (context, isLoading) => isLoading
              ? const SizedBox.expand(
                  child: IgnorePointer(child: _DotShimmerOverlay()),
                )
              : const SizedBox.shrink(),
        ),
        SafeArea(
          child: Align(
            alignment: AlignmentDirectional.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(L10n.global().imageSegmentPickerInstruction),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PointPromptMarker extends StatelessWidget {
  const _PointPromptMarker({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.circle, color: Colors.black, size: size),
          Icon(
            Icons.radio_button_checked,
            color: Colors.white,
            size: size * .8,
          ),
        ],
      ),
    );
  }

  static const size = 20.0;
}

typedef _BlocBuilder = BlocBuilder<_IspBloc, _State>;
// typedef _BlocListener = BlocListener<_IspBloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_IspBloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_IspBloc, _State, T>;
typedef _Emitter = Emitter<_State>;

extension on BuildContext {
  _IspBloc get bloc => read();
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
