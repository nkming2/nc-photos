import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_share.dart';
import 'package:nc_photos/bloc/list_sharee.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';

class ShareAlbumDialog extends StatefulWidget {
  ShareAlbumDialog({
    Key? key,
    required this.account,
    required this.file,
  });

  @override
  createState() => _ShareAlbumDialogState();

  final Account account;
  final File file;
}

class _ShareAlbumDialogState extends State<ShareAlbumDialog> {
  @override
  initState() {
    super.initState();
    _shareeBloc.add(ListShareeBlocQuery(widget.account));
    _shareBloc.add(ListShareBlocQuery(widget.account, widget.file));
  }

  @override
  build(BuildContext context) {
    return BlocListener<ListShareeBloc, ListShareeBlocState>(
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
              CircularProgressIndicator(),
              const SizedBox(width: 24),
              Text(L10n.of(context).genericProcessingDialogContent),
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
      title: Text("Share with user"),
      children: children,
    );
  }

  Widget _buildItem(
      BuildContext context, ListShareBlocState shareState, Sharee sharee) {
    final Share? share;
    if (_overrideSharee.containsKey(sharee.shareWith)) {
      share = _overrideSharee[sharee.shareWith];
    } else {
      share = shareState.items
          .where((element) => element.shareWith == sharee.shareWith)
          .firstOrNull;
    }

    final isProcessing =
        _processingSharee.any((element) => element == sharee.shareWith);
    final Widget trailing;
    if (isProcessing) {
      trailing = Container(
        child: SizedBox(
          width: 24,
          height: 24,
          child: const CircularProgressIndicator(),
        ),
      );
    } else {
      trailing = Checkbox(
        value: share != null,
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
      onPressed: () => _onShareePressed(context, sharee, share),
    );
  }

  void _onListShareeBlocStateChanged(
      BuildContext context, ListShareeBlocState state) {
    if (state is ListShareeBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onShareePressed(
      BuildContext context, Sharee sharee, Share? share) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    setState(() {
      _processingSharee.add(sharee.shareWith);
    });
    if (share == null) {
      // create new share
      try {
        final newShare = await shareRepo.create(
            widget.account, widget.file, sharee.shareWith);
        _overrideSharee[sharee.shareWith] = newShare;
      } catch (e, stackTrace) {
        _log.shout("[_onShareePressed] Failed while create", e, stackTrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e, context)),
          duration: k.snackBarDurationNormal,
        ));
      }
    } else {
      // remove share
      try {
        await shareRepo.delete(widget.account, share);
        _overrideSharee[sharee.shareWith] = null;
      } catch (e, stackTrace) {
        _log.shout("[_onShareePressed] Failed while delete", e, stackTrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e, context)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
    setState(() {
      _processingSharee.remove(sharee.shareWith);
    });
  }

  final _shareeBloc = ListShareeBloc();
  final _shareBloc = ListShareBloc();
  final _processingSharee = <String>[];

  /// Store the modified value of each sharee
  final _overrideSharee = <String, Share?>{};

  static final _log =
      Logger("widget.share_album_dialog._ShareAlbumDialogState");
}
