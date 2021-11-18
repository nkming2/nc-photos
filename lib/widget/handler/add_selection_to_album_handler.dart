import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/pref.dart';
import 'package:nc_photos/use_case/add_to_album.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';

class AddSelectionToAlbumHandler {
  Future<void> call({
    required BuildContext context,
    required Account account,
    required List<File> selectedFiles,
    required VoidCallback clearSelection,
  }) async {
    try {
      final value = await showDialog<Album>(
        context: context,
        builder: (_) => AlbumPickerDialog(
          account: account,
        ),
      );
      if (value == null) {
        // user cancelled the dialog
        return;
      }

      _log.info("[call] Album picked: ${value.name}");
      await NotifiedAction(
        () async {
          assert(value.provider is AlbumStaticProvider);
          final selected = selectedFiles
              .map((f) => AlbumFileItem(
                    addedBy: account.username,
                    addedAt: DateTime.now(),
                    file: f,
                  ))
              .toList();
          clearSelection();
          final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
          final shareRepo = ShareRepo(ShareRemoteDataSource());
          await AddToAlbum(albumRepo, shareRepo, AppDb(), Pref())(
              account, value, selected);
        },
        null,
        L10n.global().addSelectedToAlbumSuccessNotification(value.name),
        failureText: L10n.global().addSelectedToAlbumFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout("[call] Exception", e, stackTrace);
    }
  }

  static final _log = Logger(
      "widget.action.add_selection_to_album_handler.AddSelectionToAlbumHandler");
}
