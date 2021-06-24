import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/bloc/list_album.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/new_album_dialog.dart';

class AlbumPickerDialog extends StatefulWidget {
  AlbumPickerDialog({
    Key key,
    @required this.account,
  }) : super(key: key);

  @override
  createState() => _AlbumPickerDialogState();

  final Account account;
}

class _AlbumPickerDialogState extends State<AlbumPickerDialog> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return BlocListener<ListAlbumBloc, ListAlbumBlocState>(
      bloc: _bloc,
      listener: (context, state) => _onStateChange(context, state),
      child: BlocBuilder<ListAlbumBloc, ListAlbumBlocState>(
        bloc: _bloc,
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  void _initBloc() {
    ListAlbumBloc bloc;
    final blocId =
        "${widget.account.scheme}://${widget.account.username}@${widget.account.address}";
    try {
      _log.fine("[_initBloc] Resolving bloc for '$blocId'");
      bloc = KiwiContainer().resolve<ListAlbumBloc>("ListAlbumBloc($blocId)");
    } catch (_) {
      // no created instance for this account, make a new one
      _log.info("[_initBloc] New bloc instance for account: ${widget.account}");
      bloc = ListAlbumBloc();
      KiwiContainer().registerInstance<ListAlbumBloc>(bloc,
          name: "ListAlbumBloc($blocId)");
    }

    _bloc = bloc;
    if (_bloc.state is ListAlbumBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
      _reqQuery();
    } else {
      // process the current state
      _onStateChange(context, _bloc.state);
    }
  }

  Widget _buildContent(BuildContext context, ListAlbumBlocState state) {
    final newAlbumOptions = [
      SimpleDialogOption(
        onPressed: () => _onNewAlbumPressed(context),
        child: Tooltip(
          message: AppLocalizations.of(context).createAlbumTooltip,
          child: Center(
            child: Icon(
              Icons.add,
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
        ),
      ),
    ];
    return Visibility(
      visible: _isVisible,
      child: SimpleDialog(
        children: _items
                .map((e) => SimpleDialogOption(
                      onPressed: () => _onItemPressed(context, e),
                      child: ListTile(
                        title: Text("${e.name}"),
                      ),
                    ))
                .toList() +
            newAlbumOptions,
      ),
    );
  }

  void _onStateChange(BuildContext context, ListAlbumBlocState state) {
    if (state is ListAlbumBlocInit) {
      _items.clear();
    } else if (state is ListAlbumBlocSuccess || state is ListAlbumBlocLoading) {
      _transformItems(state.albums);
    } else if (state is ListAlbumBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    } else if (state is ListAlbumBlocInconsistent) {
      _reqQuery();
    }
  }

  void _onItemPressed(BuildContext context, Album album) {
    Navigator.of(context).pop(album);
  }

  void _onNewAlbumPressed(BuildContext context) {
    setState(() {
      _isVisible = false;
    });
    showDialog(
      context: context,
      builder: (_) => NewAlbumDialog(
        account: widget.account,
      ),
    ).then((value) {
      Navigator.of(context).pop(value);
    }).catchError((e, stacktrace) {
      _log.severe(
          "[_onNewAlbumPressed] Failed while showDialog", e, stacktrace);
      Navigator.of(context).pop(e);
    });
  }

  void _transformItems(List<Album> albums) {
    _items.clear();
    _items.addAll(
        albums.where((element) => element.provider is AlbumStaticProvider));
  }

  void _reqQuery() {
    _bloc.add(ListAlbumBlocQuery(widget.account));
  }

  ListAlbumBloc _bloc;

  final _items = <Album>[];

  var _isVisible = true;

  static final _log =
      Logger("widget.album_picker_dialog._AlbumPickerDialogState");
}
