import 'package:flutter/foundation.dart';
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
    _root = LsDirBlocItem(
        File(path: api_util.getWebdavRootUrlRelative(widget.account)), []);
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
    _navigateInto(
        File(path: api_util.getWebdavRootUrlRelative(widget.account)));
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
              child: state is LsDirBlocLoading
                  ? Container()
                  : _buildList(context, state),
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

  Widget _buildList(BuildContext context, LsDirBlocState state) {
    final isTopLevel =
        _currentPath == api_util.getWebdavRootUrlRelative(widget.account);
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
          key: Key(_currentPath),
          itemBuilder: (context, index) {
            if (!isTopLevel && index == 0) {
              return ListTile(
                dense: true,
                leading: const SizedBox(width: 24),
                title: Text(
                    AppLocalizations.of(context).rootPickerNavigateUpItemText),
                onTap: () {
                  try {
                    _navigateInto(File(path: path.dirname(_currentPath)));
                  } catch (e) {
                    SnackBarManager().showSnackBar(SnackBar(
                      content: Text(exception_util.toUserString(e, context)),
                      duration: k.snackBarDurationNormal,
                    ));
                  }
                },
              );
            } else {
              return _buildItem(
                  context, state.items[index - (isTopLevel ? 0 : 1)]);
            }
          },
          separatorBuilder: (context, index) => const Divider(),
          itemCount: state.items.length + (isTopLevel ? 0 : 1),
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
      if (!_fillResult(_root, state)) {
        _log.shout("[_onStateChange] Failed while _fillResult" +
            (kDebugMode
                ? ", root:\n${_root.toString(isDeep: true)}\nstate: ${state.root.path}"
                : ""));
      }
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
    final roots = _picks.map((e) => File(path: e).strippedPath).toList();
    final newAccount = widget.account.copyWith(roots: roots);
    _log.info("[_onConfirmPressed] Account is good: $newAccount");
    Navigator.of(context).pop(newAccount);
  }

  /// Fill query results from bloc to our item tree
  bool _fillResult(LsDirBlocItem root, LsDirBlocSuccess state) {
    if (root.file.path == state.root.path) {
      root.children = state.items;
      return true;
    } else if (state.root.path.startsWith(root.file.path)) {
      for (final child in root.children ?? <LsDirBlocItem>[]) {
        if (_fillResult(child, state)) {
          return true;
        }
      }
      return false;
    } else {
      // not us, not child of us
      return false;
    }
  }

  /// Pick an item
  void _pick(LsDirBlocItem item) {
    setState(() {
      _picks.add(item.file.path);
      _picks = _optimizePicks(_root);
    });
    _log.fine("[_pick] Picked: ${_pickListToString(_picks)}");
  }

  /// Optimize the picked array
  ///
  /// 1) If a parent directory is picked, all children will be ignored
  List<String> _optimizePicks(LsDirBlocItem item) {
    if (_picks.contains(item.file.path)) {
      // this dir is explicitly picked, nothing more to do
      return [item.file.path];
    }
    if (item.children == null || item.children.isEmpty) {
      return [];
    }

    final products = <String>[];
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
      if (_picks.contains(item.file.path)) {
        // ourself is being picked, simple
        _picks = _picks.where((element) => element != item.file.path).toList();
      } else {
        // Look for the closest picked dir
        final parents = _picks
            .where((element) => item.file.path.startsWith(element))
            .toList()
              ..sort((a, b) => b.length.compareTo(a.length));
        final parent = parents.first;
        try {
          _picks.addAll(_pickedAllExclude(path: parent, exclude: item)
              .map((e) => e.file.path));
          _picks.remove(parent);
        } catch (_) {
          SnackBarManager().showSnackBar(SnackBar(
              content: Text(AppLocalizations.of(context)
                  .rootPickerUnpickFailureNotification)));
        }
      }
    });
    _log.fine("[_unpick] Picked: ${_pickListToString(_picks)}");
  }

  /// Return a list where all children of [path] or [item], except [exclude],
  /// are picked
  ///
  /// Either [path] or [item] must be set, If both are set, [item] takes
  /// priority
  List<LsDirBlocItem> _pickedAllExclude({
    String path,
    LsDirBlocItem item,
    @required LsDirBlocItem exclude,
  }) {
    if (item == null) {
      final item = _findChildItemByPath(_root, path);
      return _pickedAllExclude(item: item, exclude: exclude);
    }

    if (item.file.path == exclude.file.path) {
      return [];
    }
    _log.fine(
        "[_pickedAllExclude] Unpicking '${item.file.path}' and picking children");
    final products = <LsDirBlocItem>[];
    for (final i in item.children) {
      if (exclude.file.path.startsWith(i.file.path)) {
        // [i] is a parent of exclude
        products.addAll(_pickedAllExclude(item: i, exclude: exclude));
      } else {
        products.add(i);
      }
    }
    return products;
  }

  /// Return the child/grandchild/... item of [parent] with [path]
  LsDirBlocItem _findChildItemByPath(LsDirBlocItem parent, String path) {
    if (path == parent.file.path) {
      return parent;
    }
    for (final c in parent.children) {
      if (path == c.file.path || path.startsWith("${c.file.path}/")) {
        return _findChildItemByPath(c, path);
      }
    }
    // ???
    _log.shout(
        "[_findChildItemByPath] Failed finding child item for '$path' under '${parent.file.path}'");
    throw ArgumentError("Path not found");
  }

  PickState _isItemPicked(LsDirBlocItem item) {
    var product = PickState.notPicked;
    for (final p in _picks) {
      // exact match, or parent is picked
      if (p == item.file.path || item.file.path.startsWith("$p/")) {
        product = PickState.picked;
        // no need to check the remaining ones
        break;
      }
      if (p.startsWith("${item.file.path}/")) {
        product = PickState.childPicked;
      }
    }
    if (product == PickState.childPicked) {}
    return product;
  }

  /// Return the string representation of a list of LsDirBlocItem
  static _pickListToString(List<String> items) => "['${items.join('\', \'')}']";

  void _navigateInto(File file) {
    _currentPath = file.path;
    _bloc.add(LsDirBlocQuery(widget.account, file, depth: 2));
  }

  LsDirBloc _bloc;

  LsDirBlocItem _root;

  /// Track where the user is navigating in [_backingFiles]
  String _currentPath;
  var _picks = <String>[];

  static final _log = Logger("widget.root_picker._RootPickerState");
}

enum PickState {
  notPicked,
  picked,
  childPicked,
}
