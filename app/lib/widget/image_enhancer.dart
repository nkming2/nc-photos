import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:circular_reveal_animation/circular_reveal_animation.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/any_file/any_file.dart';
import 'package:nc_photos/entity/any_file/content/factory.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/entity/pref.dart';
import 'package:nc_photos/help_utils.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/android/android_info.dart';
import 'package:nc_photos/mobile/android/k.dart' as android;
import 'package:nc_photos/mobile/local_media_image.dart';
import 'package:nc_photos/np_api_util.dart';
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/url_launcher_util.dart';
import 'package:nc_photos/widget/handler/permission_handler.dart';
import 'package:nc_photos/widget/image_editor_persist_option_dialog.dart';
import 'package:nc_photos/widget/selectable.dart';
import 'package:np_log/np_log.dart';
import 'package:np_platform_image_processor/np_platform_image_processor.dart';
import 'package:np_platform_util/np_platform_util.dart';
import 'package:np_ui/np_ui.dart';

part 'image_enhancer.g.dart';

class ImageEnhancerArguments {
  const ImageEnhancerArguments(this.account, this.file, this.isSaveToServer);

  final Account account;
  final AnyFile file;
  final bool isSaveToServer;
}

class ImageEnhancer extends StatefulWidget {
  static const routeName = "/legacy-image-enhancer";

  static Route buildRoute(
    ImageEnhancerArguments args,
    RouteSettings settings,
  ) => MaterialPageRoute(
    builder: (context) => ImageEnhancer.fromArgs(args),
    settings: settings,
  );

  static bool isSupportedMime(String mime) =>
      file_util.isSupportedImageMime(mime) && mime != "image/gif";

  const ImageEnhancer({
    super.key,
    required this.account,
    required this.file,
    required this.isSaveToServer,
  });

  ImageEnhancer.fromArgs(ImageEnhancerArguments args, {Key? key})
    : this(
        key: key,
        account: args.account,
        file: args.file,
        isSaveToServer: args.isSaveToServer,
      );

  @override
  createState() => _ImageEnhancerState();

  final Account account;
  final AnyFile file;
  final bool isSaveToServer;
}

@npLog
class _ImageEnhancerState extends State<ImageEnhancer> {
  @override
  initState() {
    super.initState();
    _c = KiwiContainer().resolve<DiContainer>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialDialogs();
    });
  }

  @override
  build(BuildContext context) => Theme(
    data: buildDarkTheme(context),
    child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: SafeArea(child: Builder(builder: _buildContent)),
      ),
    ),
  );

  Widget _buildContent(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _options.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.all(48),
                child: _options[i].showcaseBuilder(context),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 2 - 80,
              ),
              scrollDirection: Axis.horizontal,
              itemCount: _options.length,
              itemBuilder: _buildItem,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            height: 72,
            alignment: AlignmentDirectional.centerStart,
            child: Text(_selectedOption.description),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) => AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    title: Text(L10n.global().enhanceTooltip),
    actions: [
      TextButton(
        child: Text(
          L10n.global().applyButtonLabel,
          style: const TextStyle(color: Colors.white),
        ),
        onPressed: () => _onSavePressed(context),
      ),
      IconButton(
        icon: const Icon(Icons.help_outline),
        tooltip: L10n.global().helpTooltip,
        onPressed: () {
          launch(_selectedOption.link);
        },
      ),
    ],
  );

  Widget _buildItem(BuildContext context, int index) {
    final opt = _options[index];
    return _ListChild(
      title: opt.title,
      isSelected: identical(_selectedOption, opt),
      onTap: () {
        setState(() {
          _selectedOption = opt;
          _pageController.animateToPage(
            index,
            duration: k.animationDurationNormal,
            curve: Curves.easeInOut,
          );
        });
      },
    );
  }

  Future<void> _onSavePressed(BuildContext context) async {
    final args = await _getArgs(context, _selectedOption.algorithm);
    if (args == null) {
      // user canceled
      return;
    }
    final uriGetter = AnyFileContentGetterFactory.uri(
      widget.file,
      account: widget.account,
    );
    switch (_selectedOption.algorithm) {
      case _Algorithm.arbitraryStyleTransfer:
        await ImageProcessor.arbitraryStyleTransfer(
          await uriGetter.get(),
          widget.file.name,
          _isAtLeast5GbRam() ? 1400 : 1152,
          _isAtLeast5GbRam() ? 1050 : 864,
          args["styleUri"],
          args["weight"],
          headers: {
            "Authorization": AuthUtil.fromAccount(
              widget.account,
            ).toHeaderValue(),
          },
          isSaveToServer: widget.isSaveToServer,
        );
        break;
    }
    Navigator.of(context).pop();
  }

  Future<void> _showInitialDialogs() async {
    if (!mounted) {
      return;
    }
    final value = await _ensurePermission();
    if (!mounted || !value) {
      return;
    }
    if (!_c.pref.hasShownSaveEditResultDialogOr()) {
      await _showSaveEditResultDialog(context);
    }
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

  Future<Map<String, dynamic>?> _getArgs(
    BuildContext context,
    _Algorithm selected,
  ) async {
    switch (selected) {
      case _Algorithm.arbitraryStyleTransfer:
        return _getArbitraryStyleTransferArgs(context);
    }
  }

  Future<Map<String, dynamic>?> _getArbitraryStyleTransferArgs(
    BuildContext context,
  ) async {
    final result = await showDialog<_StylePickerResult>(
      context: context,
      builder: (_) => const _StylePicker(),
    );
    if (result == null) {
      // user canceled
      return null;
    } else {
      return {"styleUri": result.styleUri, "weight": result.weight};
    }
  }

  bool _isAtLeast5GbRam() {
    // We can't compare with 5 * 1024 directly as some RAM are preserved
    return AndroidInfo().totalMemMb > 4608;
  }

  late final _options = [
    if (getRawPlatform() == NpPlatform.android) ...[
      _Option(
        title: L10n.global().enhanceStyleTransferTitle,
        description: L10n.global().enhanceStyleTransferStyleDialogDescription,
        link: enhanceStyleTransferUrl,
        showcaseBuilder: (_) => const _StyleTransferShowcase(),
        algorithm: _Algorithm.arbitraryStyleTransfer,
      ),
    ],
  ];

  late final DiContainer _c;
  late var _selectedOption = _options[0];
  late final _pageController = PageController(keepPage: false);
}

enum _Algorithm { arbitraryStyleTransfer }

class _Option {
  const _Option({
    required this.title,
    required this.description,
    required this.link,
    required this.showcaseBuilder,
    required this.algorithm,
  });

  final String title;
  final String description;
  final String link;
  final Widget Function(BuildContext context) showcaseBuilder;
  final _Algorithm algorithm;
}

class _ListChild extends StatelessWidget {
  const _ListChild({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  build(BuildContext context) {
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

mixin _ShowcaseStateMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  @override
  initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250)).then((_) {
      if (mounted) {
        animController.forward();
      }
    });
  }

  @override
  dispose() {
    animController.dispose();
    super.dispose();
  }

  late final animController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );
  late final Animation<double> anim = CurvedAnimation(
    parent: animController,
    curve: Curves.easeIn,
  );
}

class _StyleTransferShowcase extends StatefulWidget {
  const _StyleTransferShowcase();

  @override
  createState() => _StyleTransferShowcaseState();
}

class _StyleTransferShowcaseState extends State<_StyleTransferShowcase>
    with TickerProviderStateMixin, _ShowcaseStateMixin {
  @override
  build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset(
        "assets/style-transfer0.jpg",
        fit: BoxFit.contain,
        gaplessPlayback: true,
      ),
      CircularRevealAnimation(
        animation: anim,
        centerAlignment: Alignment.bottomCenter,
        child: Image.asset(
          "assets/style-transfer1.jpg",
          fit: BoxFit.contain,
          gaplessPlayback: true,
        ),
      ),
    ],
  );
}

class _StylePickerResult {
  const _StylePickerResult(this.styleUri, this.weight);

  final String styleUri;
  final double weight;
}

class _StylePicker extends StatefulWidget {
  const _StylePicker();

  @override
  createState() => _StylePickerState();
}

@npLog
class _StylePickerState extends State<_StylePicker> {
  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(L10n.global().enhanceStyleTransferStyleDialogTitle),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selected != null) ...[
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 128,
                height: 128,
                child: Image(
                  image: ResizeImage.resizeIfNeeded(
                    128,
                    null,
                    LocalMediaImage(_getSelectedUri()),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            runSpacing: 8,
            spacing: 8,
            children: [
              ..._bundledStyles.mapIndexed(
                (i, e) => _buildItem(
                  i,
                  Image(
                    image: ResizeImage.resizeIfNeeded(
                      _thumbSize,
                      null,
                      LocalMediaImage(e),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              if (_customUri != null)
                _buildItem(
                  _bundledStyles.length,
                  Image(
                    image: ResizeImage.resizeIfNeeded(
                      _thumbSize,
                      null,
                      LocalMediaImage(_customUri!),
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              InkWell(
                onTap: _onCustomTap,
                child: SizedBox(
                  width: _thumbSize.toDouble(),
                  height: _thumbSize.toDouble(),
                  child: const Icon(Icons.file_open_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              const Icon(Icons.auto_fix_normal),
              Expanded(
                child: StatefulSlider(
                  initialValue: _weight,
                  min: .01,
                  onChangeEnd: (value) {
                    _weight = value;
                  },
                ),
              ),
              const Icon(Icons.auto_fix_high),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (_selected == null) {
              SnackBarManager().showSnackBar(
                SnackBar(
                  content: Text(
                    L10n.global()
                        .enhanceStyleTransferNoStyleSelectedNotification,
                  ),
                  duration: k.snackBarDurationNormal,
                ),
              );
            } else {
              final result = _StylePickerResult(_getSelectedUri(), _weight);
              Navigator.of(context).pop(result);
            }
          },
          child: Text(L10n.global().enhanceButtonLabel),
        ),
      ],
    );
  }

  Widget _buildItem(int index, Widget child) {
    return SizedBox(
      width: _thumbSize.toDouble(),
      height: _thumbSize.toDouble(),
      child: Selectable(
        isSelected: _selected == index,
        iconSize: 24,
        indicatorAlignment: Alignment.center,
        child: child,
        onTap: () {
          setState(() {
            _selected = index;
          });
        },
      ),
    );
  }

  Future<void> _onCustomTap() async {
    const intent = AndroidIntent(
      action: android.ACTION_GET_CONTENT,
      type: "image/*",
      category: android.CATEGORY_OPENABLE,
      arguments: {android.EXTRA_LOCAL_ONLY: true},
    );
    final result = await intent.launchForResult();
    _log.info("[onCustomTap] Intent result: $result");
    if (result?.resultCode == android.resultOk) {
      if (mounted) {
        setState(() {
          _customUri = result!.data;
          _selected = _bundledStyles.length;
        });
      }
    }
  }

  String _getSelectedUri() {
    return _selected! < _bundledStyles.length
        ? _bundledStyles[_selected!]
        : _customUri!;
  }

  int? _selected;
  String? _customUri;
  double _weight = .85;

  static const _thumbSize = 56;
  static const _bundledStyles = [
    "file:///android_asset/tf/arbitrary-style-transfer/1.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/2.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/3.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/4.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/5.jpg",
    "file:///android_asset/tf/arbitrary-style-transfer/6.jpg",
  ];
}
