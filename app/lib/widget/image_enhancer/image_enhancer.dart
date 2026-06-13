import 'dart:async';

import 'package:copy_with/copy_with.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc_util.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/any_file/any_file.dart';
import 'package:nc_photos/entity/any_file/content/factory.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/exception_event.dart';
import 'package:nc_photos/exception_util.dart';
import 'package:nc_photos/help_utils.dart' as help_util;
import 'package:nc_photos/image_enhancer_task.dart';
import 'package:nc_photos/image_enhancer_util.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/handler/permission_handler.dart';
import 'package:nc_photos/widget/image_editor_persist_option_dialog.dart';
import 'package:np_log/np_log.dart';
import 'package:to_string/to_string.dart';
import 'package:workmanager/workmanager.dart';

part 'bloc.dart';
part 'dialog.dart';
part 'image_enhancer.g.dart';
part 'state_event.dart';
part 'type.dart';

class ImageEnhancerArguments {
  const ImageEnhancerArguments(this.file);

  final AnyFile file;
}

class ImageEnhancer extends StatelessWidget {
  static const routeName = "/image-enhancer";

  static Route buildRoute(
    ImageEnhancerArguments args,
    RouteSettings settings,
  ) => MaterialPageRoute(
    builder: (context) => ImageEnhancer.fromArgs(args),
    settings: settings,
  );

  static bool isSupportedMime(String mime) =>
      file_util.isSupportedImageMime(mime) && mime != "image/gif";

  const ImageEnhancer({super.key, required this.file});

  ImageEnhancer.fromArgs(ImageEnhancerArguments args, {Key? key})
    : this(key: key, file: args.file);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _IeBloc(
        account: context.read<AccountController>().account,
        file: file,
      ),
      child: const _WrappedImageEnhancer(),
    );
  }

  final AnyFile file;
}

class _WrappedImageEnhancer extends StatefulWidget {
  const _WrappedImageEnhancer();

  @override
  State<StatefulWidget> createState() => _WrappedImageEnhancerState();
}

class _WrappedImageEnhancerState extends State<_WrappedImageEnhancer> {
  @override
  void initState() {
    super.initState();
    _ensurePermission().then((value) {
      if (value && mounted) {
        final c = KiwiContainer().resolve<DiContainer>();
        if (!c.pref.hasShownSaveEditResultDialogOr()) {
          _showSaveEditResultDialog(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: buildDarkTheme(context),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.black,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: MultiBlocListener(
          listeners: [
            _BlocListenerT(
              selector: (state) => state.applyError,
              listener: (context, applyError) {
                if (applyError != null) {
                  final (text, action) = exceptionToSnackBarData(
                    applyError.error,
                  );
                  SnackBarManager().showSnackBar(
                    SnackBar(
                      content: Text(
                        "${L10n.global().imageEditSaveErrorMessage} ($text)",
                      ),
                      persist: false,
                      action: action,
                      duration: k.snackBarDurationNormal,
                    ),
                  );
                }
              },
            ),
          ],
          child: _BlocBuilder(
            buildWhen: (previous, current) =>
                previous.saveState != current.saveState,
            builder: (context, state) => PopScope(
              canPop: state.saveState == null,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(L10n.global().enhanceTooltip),
                  actions: [
                    TextButton(
                      onPressed: state.saveState == null
                          ? () {
                              context.addEvent(const _Apply());
                            }
                          : null,
                      child: Text(L10n.global().applyButtonLabel),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline),
                      tooltip: L10n.global().helpTooltip,
                      onPressed: () {
                        context.addEvent(const _Help());
                      },
                    ),
                  ],
                ),
                body: Stack(
                  children: [
                    const SafeArea(child: _Body()),
                    _BlocSelector(
                      selector: (state) => state.saveState,
                      builder: (context, saveState) => saveState != null
                          ? const _SaveDialog()
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _ensurePermission() async {
    if (!await const PermissionHandler().ensureStorageWritePermission()) {
      if (mounted) {
        Navigator.of(context).pop();
      }
      return false;
    } else {
      return true;
    }
  }

  Future<void> _showSaveEditResultDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const ImageEditorPersistOptionDialog(isFromEditor: false),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Expanded(child: _MethodShowcase()),
        _MethodSelector(),
        SizedBox(height: 8),
        _MethodDetails(),
      ],
    );
  }
}

class _MethodShowcase extends StatefulWidget {
  const _MethodShowcase();

  @override
  State<StatefulWidget> createState() => _MethodShowcaseState();
}

class _MethodShowcaseState extends State<_MethodShowcase> {
  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _Method.values.length,
      itemBuilder: (context, i) {
        final m = _Method.values[i];
        return Padding(padding: const EdgeInsets.all(48), child: Text(m.name));
      },
    );
  }

  late final _pageController = PageController(keepPage: false);
}

class _MethodSelector extends StatelessWidget {
  const _MethodSelector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView.builder(
          padding: EdgeInsets.symmetric(
            horizontal: constraints.maxWidth / 2 - 80,
          ),
          scrollDirection: Axis.horizontal,
          itemCount: _Method.values.length,
          itemBuilder: (context, index) {
            final m = _Method.values[index];
            return _BlocSelector(
              selector: (state) => state.selectedMethod,
              builder: (context, selectedMethod) => _MethodOptionView(
                title: m.title,
                isSelected: m == selectedMethod,
                onTap: () {
                  context.addEvent(_SelectMethod(m));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MethodOptionView extends StatelessWidget {
  const _MethodOptionView({
    required this.title,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(24)),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          child: Container(
            color: isSelected
                ? Theme.of(context).colorScheme.secondaryContainer
                : null,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSecondaryContainer
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  final String title;
  final bool isSelected;
  final VoidCallback? onTap;
}

class _MethodDetails extends StatelessWidget {
  const _MethodDetails();

  @override
  Widget build(BuildContext context) {
    return _BlocSelector(
      selector: (state) => state.selectedMethod,
      builder: (context, selectedMethod) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        height: 72,
        alignment: AlignmentDirectional.centerStart,
        child: Text(selectedMethod.description),
      ),
    );
  }
}

typedef _BlocBuilder = BlocBuilder<_IeBloc, _State>;
// typedef _BlocListener = BlocListener<_IeBloc, _State>;
typedef _BlocListenerT<T> = BlocListenerT<_IeBloc, _State, T>;
typedef _BlocSelector<T> = BlocSelector<_IeBloc, _State, T>;
typedef _Emitter = Emitter<_State>;

extension on BuildContext {
  _IeBloc get bloc => read();
  // _State get state => bloc.state;
  void addEvent(_Event event) => bloc.add(event);
}
