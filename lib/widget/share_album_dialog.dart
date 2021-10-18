import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_share.dart';
import 'package:nc_photos/bloc/list_sharee.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/share_album_with_user.dart';
import 'package:nc_photos/use_case/unshare_album_with_user.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';

class ShareAlbumDialog extends StatefulWidget {
  ShareAlbumDialog({
    Key? key,
    required this.account,
    required this.album,
  })  : assert(album.albumFile != null),
        super(key: key);

  @override
  createState() => _ShareAlbumDialogState();

  final Account account;
  final Album album;
}

class _ShareAlbumDialogState extends State<ShareAlbumDialog> {
  @override
  initState() {
    super.initState();
    _shareeBloc.add(ListShareeBlocQuery(widget.account));
    _shareBloc.add(ListShareBlocQuery(widget.account, widget.album.albumFile!));
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: BlocListener<ListShareeBloc, ListShareeBlocState>(
            bloc: _shareeBloc,
            listener: (context, shareeState) =>
                _onListShareeBlocStateChanged(context, shareeState),
            child: BlocBuilder<ListShareeBloc, ListShareeBlocState>(
              bloc: _shareeBloc,
              builder: (_, shareeState) =>
                  BlocBuilder<ListShareBloc, ListShareBlocState>(
                bloc: _shareBloc,
                builder: (context, shareState) =>
                    _buildContent(context, shareeState, shareState),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ListShareeBlocState shareeState,
      ListShareBlocState shareState) {
    final List<Widget> children;
    if (shareeState is ListShareeBlocLoading ||
        shareState is ListShareBlocLoading) {
      children = [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 24),
              Text(L10n.global().genericProcessingDialogContent),
            ],
          ),
        ),
      ];
    } else {
      children = shareeState.items
          .where((element) => element.type == ShareeType.user)
          .sorted((a, b) => a.label.compareTo(b.label))
          .map((sharee) => _buildItem(context, shareState, sharee))
          .toList();
    }
    return SimpleDialog(
      title: const Text("Share with user"),
      children: children,
    );
  }

  Widget _buildItem(
      BuildContext context, ListShareBlocState shareState, Sharee sharee) {
    final bool isShared;
    if (_overrideSharee.containsKey(sharee.shareWith)) {
      isShared = _overrideSharee[sharee.shareWith]!;
    } else {
      isShared = shareState.items
          .any((element) => element.shareWith == sharee.shareWith);
    }

    final isProcessing =
        _processingSharee.any((element) => element == sharee.shareWith);
    final Widget trailing;
    if (isProcessing) {
      trailing = Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppTheme.getUnfocusedIconColor(context),
          ),
        ),
      );
    } else {
      trailing = Checkbox(
        value: isShared,
        onChanged: (value) {},
      );
    }
    return SimpleDialogOption(
      child: ListTile(
        dense: true,
        title: Text(sharee.label),
        // pass through the tap event
        trailing: IgnorePointer(
          child: trailing,
        ),
      ),
      onPressed: () => _onShareePressed(sharee, isShared),
    );
  }

  void _onListShareeBlocStateChanged(
      BuildContext context, ListShareeBlocState state) {
    if (state is ListShareeBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onShareePressed(Sharee sharee, bool isShared) async {
    setState(() {
      _processingSharee.add(sharee.shareWith);
    });
    if (!isShared) {
      // create new share
      await _createShare(sharee);
    } else {
      // remove share
      await _removeShare(sharee);
    }
    setState(() {
      _processingSharee.remove(sharee.shareWith);
    });
  }

  void _onFixPressed() {
    Navigator.of(context).pushNamed(AlbumShareOutlierBrowser.routeName,
        arguments:
            AlbumShareOutlierBrowserArguments(widget.account, widget.album));
  }

  Future<void> _createShare(Sharee sharee) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    var hasFailure = false;
    try {
      await ShareAlbumWithUser(shareRepo)(
        widget.account,
        widget.album,
        sharee.shareWith,
        onShareFileFailed: (_) {
          hasFailure = true;
        },
      );
      _overrideSharee[sharee.shareWith] = true;
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(hasFailure
            ? L10n.global()
                .shareAlbumSuccessWithErrorNotification(sharee.shareWith)
            : L10n.global().shareAlbumSuccessNotification(sharee.shareWith)),
        action: hasFailure
            ? SnackBarAction(
                label: L10n.global().fixButtonLabel,
                textColor: Theme.of(context).colorScheme.secondaryVariant,
                onPressed: _onFixPressed,
              )
            : null,
        duration: k.snackBarDurationNormal,
      ));
    } catch (e, stackTrace) {
      _log.shout(
          "[_createShare] Failed while ShareAlbumWithUser", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<void> _removeShare(Sharee sharee) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final fileRepo = FileRepo(FileCachedDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource());
    var hasFailure = false;
    try {
      await UnshareAlbumWithUser(shareRepo, fileRepo, albumRepo)(
        widget.account,
        widget.album,
        sharee.shareWith,
        onUnshareFileFailed: (_) {
          hasFailure = true;
        },
      );
      _overrideSharee[sharee.shareWith] = false;
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(hasFailure
            ? L10n.global()
                .unshareAlbumSuccessWithErrorNotification(sharee.shareWith)
            : L10n.global().unshareAlbumSuccessNotification(sharee.shareWith)),
        action: hasFailure
            ? SnackBarAction(
                label: L10n.global().fixButtonLabel,
                textColor: Theme.of(context).colorScheme.secondaryVariant,
                onPressed: _onFixPressed,
              )
            : null,
        duration: k.snackBarDurationNormal,
      ));
    } catch (e, stackTrace) {
      _log.shout(
          "[_removeShare] Failed while UnshareAlbumWithUser", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  final _shareeBloc = ListShareeBloc();
  final _shareBloc = ListShareBloc();
  final _processingSharee = <String>[];

  /// Store the modified value of each sharee
  final _overrideSharee = <String, bool>{};

  static final _log =
      Logger("widget.share_album_dialog._ShareAlbumDialogState");
}
