import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/bloc/ls_dir.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:path/path.dart' as path;

class RootPickerArguments {
  RootPickerArguments(this.account);

  final Account account;
}

class RootPicker extends StatefulWidget {
  static const routeName = "/root-picker";

  RootPicker({
    Key key,
    @required this.account,
  }) : super(key: key);

  RootPicker.fromArgs(RootPickerArguments args, {Key key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _RootPickerState();

  final Account account;
}

class _RootPickerState extends State<RootPicker> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: BlocListener<LsDirBloc, LsDirBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<LsDirBloc, LsDirBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    _log.info("[_initBloc] Initialize bloc");
    _bloc = LsDirBloc();
    _bloc.add(LsDirBlocQuery(widget.account,
        [File(path: api_util.getWebdavRootUrlRelative(widget.account))]));
  }

  Widget _buildContent(BuildContext context, LsDirBlocState state) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context).rootPickerHeaderText,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    AppLocalizations.of(context).rootPickerSubHeaderText,
                  ),
                ),
              ],
            ),
          ),
          if (state is LsDirBlocLoading)
            Align(
              alignment: Alignment.topCenter,
              child: const LinearProgressIndicator(),
            ),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: _buildList(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!ModalRoute.of(context).isFirst)
                  TextButton(
                    onPressed: () => _onSkipPressed(context),
                    child: Text(AppLocalizations.of(context).skipButtonLabel),
                  )
                else
                  Container(),
                ElevatedButton(
                  onPressed: () => _onConfirmPressed(context),
                  child: Text(AppLocalizations.of(context).confirmButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    final current = _findCurrentNavigateLevel();
    final isTopLevel = _positions.isEmpty;
    return Theme(
      data: Theme.of(context).copyWith(
        accentColor: AppTheme.getOverscrollIndicatorColor(context),
      ),
      child: AnimatedSwitcher(
        duration: k.animationDurationNormal,
        // see AnimatedSwitcher.defaultLayoutBuilder
        layoutBuilder: (currentChild, previousChildren) => Stack(
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
          alignment: Alignment.topLeft,
        ),
        child: ListView.separated(
          key: ObjectKey(current),
          itemBuilder: (context, index) {
            if (!isTopLevel && index == 0) {
              return ListTile(
                dense: true,
                leading: const SizedBox(width: 24),
                title: Text(
                    AppLocalizations.of(context).rootPickerNavigateUpItemText),
                onTap: () {
                  try {
                    _navigateUp();
                  } catch (e) {
                    SnackBarManager().showSnackBar(SnackBar(
                      content: Text(exception_util.toUserString(e, context)),
                      duration: k.snackBarDurationNormal,
                    ));
                  }
                },
              );
            } else {
              return _buildItem(context, current[index - (isTopLevel ? 0 : 1)]);
            }
          },
          separatorBuilder: (context, index) => const Divider(),
          itemCount: current.length + (isTopLevel ? 0 : 1),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, LsDirBlocItem item) {
    final pickState = _isItemPicked(item);

    IconData iconData;
    switch (pickState) {
      case PickState.picked:
        iconData = Icons.check_box;
        break;
      case PickState.childPicked:
        iconData = Icons.indeterminate_check_box;
        break;
      case PickState.notPicked:
      default:
        iconData = Icons.check_box_outline_blank;
        break;
    }

    return ListTile(
      dense: true,
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: k.animationDurationShort,
          transitionBuilder: (child, animation) =>
              ScaleTransition(child: child, scale: animation),
          child: Icon(
            iconData,
            key: ValueKey(pickState),
          ),
        ),
        onPressed: () {
          if (pickState == PickState.picked) {
            _unpick(item);
          } else {
            _pick(item);
          }
        },
      ),
      title: Text(path.basename(item.file.path)),
      trailing:
          item.children.isNotEmpty ? const Icon(Icons.arrow_forward_ios) : null,
      onTap: item.children.isNotEmpty
          ? () {
              try {
                _navigateInto(item.file);
              } catch (e) {
                SnackBarManager().showSnackBar(SnackBar(
                  content: Text(exception_util.toUserString(e, context)),
                  duration: k.snackBarDurationNormal,
                ));
              }
            }
          : null,
    );
  }

  void _onStateChange(BuildContext context, LsDirBlocState state) {
    if (state is LsDirBlocSuccess) {
      _positions = [];
      _root = LsDirBlocItem(File(path: "/"), state.items);
    } else if (state is LsDirBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onSkipPressed(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: Text(AppLocalizations.of(context)
                  .rootPickerSkipConfirmationDialogContent),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: Text(MaterialLocalizations.of(context).okButtonLabel),
                ),
              ],
            )).then((value) {
      if (value == true) {
        // default is to include all files, so we just return the same account
        Navigator.of(context).pop(widget.account);
      }
    });
  }

  void _onConfirmPressed(BuildContext context) {
    final roots = _picks.map((e) => e.file.strippedPath).toList();
    final newAccount = widget.account.copyWith(roots: roots);
    _log.info("[_onConfirmPressed] Account is good: $newAccount");
    Navigator.of(context).pop(newAccount);
  }

  /// Pick an item
  void _pick(LsDirBlocItem item) {
    setState(() {
      _picks.add(item);
      _picks = _optimizePicks(_root);
    });
    _log.fine("[_pick] Picked: ${_pickListToString(_picks)}");
  }

  /// Optimize the picked array
  ///
  /// 1) If a parent directory is picked, all children will be ignored
  List<LsDirBlocItem> _optimizePicks(LsDirBlocItem item) {
    if (_picks.contains(item)) {
      // this dir is explicitly picked, nothing more to do
      return [item];
    }
    if (item.children.isEmpty) {
      return [];
    }

    final products = <LsDirBlocItem>[];
    for (final i in item.children) {
      products.addAll(_optimizePicks(i));
    }
    // // see if all children are being picked
    // if (item != _root &&
    //     products.length >= item.children.length &&
    //     item.children.every((element) => products.contains(element))) {
    //   // all children are being picked, add [item] to list and remove its
    //   // children
    //   _log.fine(
    //       "[_optimizePicks] All children under '${item.file.path}' are being picked, optimized");
    //   return products
    //       .where((element) => !item.children.contains(element))
    //       .toList()
    //         ..add(item);
    // }
    return products;
  }

  /// Unpick an item
  void _unpick(LsDirBlocItem item) {
    setState(() {
      if (_picks.contains(item)) {
        // ourself is being picked, simple
        _picks = _picks.where((element) => element != item).toList();
      } else {
        // Look for the closest picked dir
        final parents = _picks
            .where((element) => item.file.path.startsWith(element.file.path))
            .toList()
              ..sort(
                  (a, b) => b.file.path.length.compareTo(a.file.path.length));
        final parent = parents.first;
        _picks.remove(parent);
        _picks.addAll(_pickedAllExclude(parent, item));
      }
    });
    _log.fine("[_unpick] Picked: ${_pickListToString(_picks)}");
  }

  /// Return a list where all children of [item] but [exclude] are picked
  List<LsDirBlocItem> _pickedAllExclude(
      LsDirBlocItem item, LsDirBlocItem exclude) {
    if (item == exclude) {
      return [];
    }
    _log.fine(
        "[_pickedAllExclude] Unpicking '${item.file.path}' and picking children");
    final products = <LsDirBlocItem>[];
    for (final i in item.children) {
      if (exclude.file.path.startsWith(i.file.path)) {
        // [i] is a parent of exclude
        products.addAll(_pickedAllExclude(i, exclude));
      } else {
        products.add(i);
      }
    }
    return products;
  }

  PickState _isItemPicked(LsDirBlocItem item) {
    var product = PickState.notPicked;
    for (final p in _picks) {
      // exact match, or parent is picked
      if (p.file.path == item.file.path ||
          item.file.path.startsWith("${p.file.path}/")) {
        product = PickState.picked;
        // no need to check the remaining ones
        break;
      }
      if (p.file.path.startsWith("${item.file.path}/")) {
        product = PickState.childPicked;
      }
    }
    if (product == PickState.childPicked) {}
    return product;
  }

  /// Return the string representation of a list of LsDirBlocItem
  static _pickListToString(List<LsDirBlocItem> items) =>
      "['${items.map((e) => e.file.path).join('\', \'')}']";

  void _navigateInto(File file) {
    final current = _findCurrentNavigateLevel();
    final navPosition =
        current.indexWhere((element) => element.file.path == file.path);
    if (navPosition == -1) {
      _log.severe("[_navigateInto] File not found: '${file.path}', "
          "current level: ['${current.map((e) => e.file.path).join('\', \'')}']");
      throw StateError("Can't navigate into directory");
    }
    setState(() {
      _positions.add(navPosition);
    });
  }

  void _navigateUp() {
    if (_positions.isEmpty) {
      throw StateError("Can't navigate up in the root directory");
    }
    setState(() {
      _positions.removeLast();
    });
  }

  /// Find and return the list of items currently navigated to
  List<LsDirBlocItem> _findCurrentNavigateLevel() {
    var product = _root.children;
    for (final i in _positions) {
      product = product[i].children;
    }
    return product;
  }

  LsDirBloc _bloc;

  var _root = LsDirBlocItem(File(path: "/"), const []);

  /// Track where the user is navigating in [_backingFiles]
  var _positions = <int>[];
  var _picks = <LsDirBlocItem>[];

  static final _log = Logger("widget.root_picker._RootPickerState");
}

enum PickState {
  notPicked,
  picked,
  childPicked,
}
