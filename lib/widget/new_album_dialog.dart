import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/use_case/create_album.dart';

/// Dialog to create a new album
///
/// The created album will be popped to the previous route, or null if user
/// cancelled
class NewAlbumDialog extends StatefulWidget {
  NewAlbumDialog({
    Key key,
    @required this.account,
  }) : super(key: key);

  @override
  createState() => _NewAlbumDialogState();

  final Account account;
}

class _NewAlbumDialogState extends State<NewAlbumDialog> {
  @override
  initState() {
    super.initState();
  }

  @override
  build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).createAlbumTooltip),
      content: Form(
        key: _formKey,
        child: TextFormField(
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context).nameInputHint,
          ),
          validator: (value) {
            if (value.isEmpty) {
              return AppLocalizations.of(context).albumNameInputInvalidEmpty;
            }
            return null;
          },
          onSaved: (value) {
            _formValue.name = value;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _onOkPressed(context),
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }

  void _onOkPressed(BuildContext context) {
    if (_formKey.currentState.validate()) {
      _formKey.currentState.save();
      final album = Album(
        name: _formValue.name,
        items: const [],
      );
      _log.info("[_onOkPressed] Creating album: $album");
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      final newAlbum = CreateAlbum(albumRepo)(widget.account, album);
      // let previous route to handle this future
      Navigator.of(context).pop(newAlbum);
    }
  }

  final _formKey = GlobalKey<FormState>();

  final _formValue = _FormValue();

  static final _log = Logger("widget.new_album_dialog._AlbumPickerDialogState");
}

class _FormValue {
  String name;
}
