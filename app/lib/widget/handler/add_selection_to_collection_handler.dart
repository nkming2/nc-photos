import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/controller/account_controller.dart';
import 'package:nc_photos/entity/collection.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/widget/collection_picker.dart';
import 'package:np_codegen/np_codegen.dart';

part 'add_selection_to_collection_handler.g.dart';

@npLog
class AddSelectionToCollectionHandler {
  const AddSelectionToCollectionHandler();

  Future<void> call({
    required BuildContext context,
    required List<FileDescriptor> selection,
    VoidCallback? clearSelection,
  }) async {
    try {
      final collection = await Navigator.of(context)
          .pushNamed<Collection>(CollectionPicker.routeName);
      if (collection == null) {
        return;
      }
      _log.info("[call] Collection picked: ${collection.name}");

      clearSelection?.call();
      final controller = context
          .read<AccountController>()
          .collectionsController
          .stream
          .value
          .itemsControllerByCollection(collection);
      Object? error;
      final s = controller.stream.listen((_) {}, onError: (e) => error = e);
      await controller.addFiles(selection);
      await s.cancel();
      if (error != null) {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().addSelectedToAlbumFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
      }
    } catch (e, stackTrace) {
      _log.shout("[call] Exception", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().addSelectedToAlbumFailureNotification),
        duration: k.snackBarDurationNormal,
      ));
    }
  }
}
