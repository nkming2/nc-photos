import 'package:flutter/material.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/tag.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/use_case/create_album.dart';
import 'package:nc_photos/widget/album_dir_picker.dart';
import 'package:nc_photos/widget/tag_picker_dialog.dart';

/// Dialog to create a new album
///
/// The created album will be popped to the previous route, or null if user
/// cancelled
class NewAlbumDialog extends StatefulWidget {
  const NewAlbumDialog({
    Key? key,
    required this.account,
    this.isAllowDynamic = true,
  }) : super(key: key);

  @override
  createState() => _NewAlbumDialogState();

  final Account account;
  final bool isAllowDynamic;
}

class _NewAlbumDialogState extends State<NewAlbumDialog> {
  @override
  initState() {
    super.initState();
  }

  @override
  build(BuildContext context) {
    return Visibility(
      visible: _isVisible,
      child: AlertDialog(
        title: Text(L10n.global().createCollectionTooltip),
        content: Form(
          key: _formKey,
          child: Container(
            constraints: const BoxConstraints.tightFor(width: 280),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    hintText: L10n.global().nameInputHint,
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return L10n.global().albumNameInputInvalidEmpty;
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _formValue.name = value!;
                  },
                ),
                if (widget.isAllowDynamic) ...[
                  DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<_Provider>(
                      value: _provider,
                      items: _Provider.values
                          .map((e) => DropdownMenuItem<_Provider>(
                                value: e,
                                child: Text(e.toValueString(context)),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _provider = newValue!;
                        });
                      },
                      onSaved: (value) {
                        _formValue.provider = value;
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _provider.toDescription(context),
                    style: Theme.of(context).textTheme.bodyText2,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _onOkPressed(context),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  void _onOkPressed(BuildContext context) {
    if (_formKey.currentState?.validate() == true) {
      _formKey.currentState!.save();
      switch (_formValue.provider) {
        case _Provider.static:
        case null:
          _onConfirmStaticAlbum();
          break;
        case _Provider.dir:
          _onConfirmDirAlbum();
          break;
        case _Provider.tag:
          _onConfirmTagAlbum();
          break;
      }
    }
  }

  Future<void> _onConfirmStaticAlbum() async {
    try {
      final album = Album(
        name: _formValue.name,
        provider: AlbumStaticProvider(
          items: const [],
        ),
        coverProvider: AlbumAutoCoverProvider(),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
      );
      _log.info("[_onConfirmStaticAlbum] Creating static album: $album");
      final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
      final newAlbum = await CreateAlbum(albumRepo)(widget.account, album);
      Navigator.of(context).pop(newAlbum);
    } catch (e, stacktrace) {
      _log.shout("[_onConfirmStaticAlbum] Failed", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> _onConfirmDirAlbum() async {
    setState(() {
      _isVisible = false;
    });
    try {
      final dirs = await Navigator.of(context).pushNamed<List<File>>(
          AlbumDirPicker.routeName,
          arguments: AlbumDirPickerArguments(widget.account));
      if (dirs == null) {
        Navigator.of(context).pop();
        return;
      }
      final album = Album(
        name: _formValue.name,
        provider: AlbumDirProvider(
          dirs: dirs,
        ),
        coverProvider: AlbumAutoCoverProvider(),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
      );
      _log.info("[_onConfirmDirAlbum] Creating dir album: $album");
      final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
      final newAlbum = await CreateAlbum(albumRepo)(widget.account, album);
      Navigator.of(context).pop(newAlbum);
    } catch (e, stacktrace) {
      _log.shout("[_onConfirmDirAlbum] Failed", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    }
  }

  Future<void> _onConfirmTagAlbum() async {
    setState(() {
      _isVisible = false;
    });
    try {
      final tags = await showDialog<List<Tag>>(
        context: context,
        builder: (_) => TagPickerDialog(account: widget.account),
      );
      if (tags == null || tags.isEmpty) {
        Navigator.of(context).pop();
        return;
      }
      final album = Album(
        name: _formValue.name,
        provider: AlbumTagProvider(tags: tags),
        coverProvider: AlbumAutoCoverProvider(),
        sortProvider: const AlbumTimeSortProvider(isAscending: false),
      );
      _log.info(
          "[_onConfirmTagAlbum] Creating tag album: ${tags.map((t) => t.displayName).join(", ")}");
      final c = KiwiContainer().resolve<DiContainer>();
      final newAlbum = await CreateAlbum(c.albumRepo)(widget.account, album);
      Navigator.of(context).pop(newAlbum);
    } catch (e, stackTrace) {
      _log.shout("[_onConfirmTagAlbum] Failed", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    }
  }

  final _formKey = GlobalKey<FormState>();
  var _provider = _Provider.static;

  final _formValue = _FormValue();

  var _isVisible = true;

  static final _log = Logger("widget.new_album_dialog._NewAlbumDialogState");
}

class _FormValue {
  late String name;
  _Provider? provider;
}

enum _Provider {
  static,
  dir,
  tag,
}

extension on _Provider {
  String toValueString(BuildContext context) {
    switch (this) {
      case _Provider.static:
        return L10n.global().createCollectionDialogAlbumLabel;
      case _Provider.dir:
        return L10n.global().createCollectionDialogFolderLabel;
      case _Provider.tag:
        return L10n.global().createCollectionDialogTagLabel;
      default:
        throw StateError("Unknown value: $this");
    }
  }

  String toDescription(BuildContext context) {
    switch (this) {
      case _Provider.static:
        return L10n.global().createCollectionDialogAlbumDescription;
      case _Provider.dir:
        return L10n.global().createCollectionDialogFolderDescription;
      case _Provider.tag:
        return L10n.global().createCollectionDialogTagDescription;
      default:
        throw StateError("Unknown value: $this");
    }
  }
}
