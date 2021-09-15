import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:exifdart/exifdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/debug_util.dart';
import 'package:nc_photos/double_extension.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/mobile/platform.dart'
    if (dart.library.html) 'package:nc_photos/web/platform.dart' as platform;
import 'package:nc_photos/notified_action.dart';
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/platform/k.dart' as platform_k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/add_to_album.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/use_case/update_property.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:nc_photos/widget/photo_date_time_edit_dialog.dart';
import 'package:path/path.dart';
import 'package:tuple/tuple.dart';

class ViewerDetailPane extends StatefulWidget {
  const ViewerDetailPane({
    Key? key,
    required this.account,
    required this.file,
    this.album,
    this.onSlideshowPressed,
  }) : super(key: key);

  @override
  createState() => _ViewerDetailPaneState();

  final Account account;
  final File file;

  /// The album this file belongs to, or null
  final Album? album;

  final VoidCallback? onSlideshowPressed;
}

class _ViewerDetailPaneState extends State<ViewerDetailPane> {
  @override
  initState() {
    super.initState();

    _dateTime = widget.file.bestDateTime.toLocal();
    if (widget.file.metadata == null) {
      _log.info("[initState] Metadata missing in File");
    } else {
      _log.info("[initState] Metadata exists in File");
      if (widget.file.metadata!.exif != null) {
        _initMetadata();
      }
    }
  }

  @override
  build(BuildContext context) {
    final dateStr = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY,
            Localizations.localeOf(context).languageCode)
        .format(_dateTime);
    final timeStr = DateFormat(DateFormat.HOUR_MINUTE,
            Localizations.localeOf(context).languageCode)
        .format(_dateTime);

    String sizeSubStr = "";
    const space = "    ";
    if (widget.file.metadata?.imageWidth != null &&
        widget.file.metadata?.imageHeight != null) {
      final pixelCount = widget.file.metadata!.imageWidth! *
          widget.file.metadata!.imageHeight!;
      if (pixelCount >= 500000) {
        final mpCount = pixelCount / 1000000.0;
        sizeSubStr += L10n.global().megapixelCount(mpCount.toStringAsFixed(1));
        sizeSubStr += space;
      }
      sizeSubStr += _byteSizeToString(widget.file.contentLength ?? 0);
    }

    String cameraSubStr = "";
    if (_fNumber != null) {
      cameraSubStr += "f/${_fNumber!.toStringAsFixed(1)}$space";
    }
    if (_exposureTime != null) {
      cameraSubStr += L10n.global().secondCountSymbol(_exposureTime!);
      cameraSubStr += space;
    }
    if (_focalLength != null) {
      cameraSubStr += L10n.global()
          .millimeterCountSymbol(_focalLength!.toStringAsFixedTruncated(2));
      cameraSubStr += space;
    }
    if (_isoSpeedRatings != null) {
      cameraSubStr += "ISO$_isoSpeedRatings$space";
    }
    cameraSubStr = cameraSubStr.trim();

    return Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (widget.album != null &&
                    widget.album!.albumFile?.isOwned(widget.account.username) ==
                        true &&
                    widget.album!.provider is AlbumStaticProvider)
                  _DetailPaneButton(
                    icon: Icons.remove_outlined,
                    label: L10n.global().removeFromAlbumTooltip,
                    onPressed: () => _onRemoveFromAlbumPressed(context),
                  ),
                if (widget.album != null &&
                    widget.album!.albumFile?.isOwned(widget.account.username) ==
                        true)
                  _DetailPaneButton(
                    icon: Icons.photo_album_outlined,
                    label: L10n.global().useAsAlbumCoverTooltip,
                    onPressed: () => _onSetAlbumCoverPressed(context),
                  ),
                _DetailPaneButton(
                  icon: Icons.playlist_add_outlined,
                  label: L10n.global().addToAlbumTooltip,
                  onPressed: () => _onAddToAlbumPressed(context),
                ),
                if (widget.file.isArchived == true)
                  _DetailPaneButton(
                    icon: Icons.unarchive_outlined,
                    label: L10n.global().unarchiveTooltip,
                    onPressed: () => _onUnarchivePressed(context),
                  )
                else
                  _DetailPaneButton(
                    icon: Icons.archive_outlined,
                    label: L10n.global().archiveTooltip,
                    onPressed: () => _onArchivePressed(context),
                  ),
                _DetailPaneButton(
                  icon: Icons.slideshow_outlined,
                  label: L10n.global().slideshowTooltip,
                  onPressed: widget.onSlideshowPressed,
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Divider(),
          ),
          ListTile(
            leading: SizedBox(
              height: double.infinity,
              child: Icon(
                Icons.image_outlined,
                color: AppTheme.getSecondaryTextColor(context),
              ),
            ),
            title: Text(basenameWithoutExtension(widget.file.path)),
            subtitle: Text(widget.file.strippedPath),
          ),
          if (!widget.file.isOwned(widget.account.username))
            ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: Icon(
                  Icons.share_outlined,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              title: Text(widget.file.ownerId!),
              subtitle: Text(L10n.global().fileSharedByDescription),
            ),
          ListTile(
            leading: Icon(
              Icons.calendar_today_outlined,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            title: Text("$dateStr $timeStr"),
            trailing: Icon(
              Icons.edit_outlined,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            onTap: () => _onDateTimeTap(context),
          ),
          if (widget.file.metadata?.imageWidth != null &&
              widget.file.metadata?.imageHeight != null)
            ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: Icon(
                  Icons.aspect_ratio,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              title: Text(
                  "${widget.file.metadata!.imageWidth} x ${widget.file.metadata!.imageHeight}"),
              subtitle: Text(sizeSubStr),
            )
          else
            ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: Icon(
                  Icons.aspect_ratio,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              title: Text(_byteSizeToString(widget.file.contentLength ?? 0)),
            ),
          if (_model != null)
            ListTile(
              leading: SizedBox(
                height: double.infinity,
                child: Icon(
                  Icons.camera_outlined,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
              title: Text(_model!),
              subtitle: cameraSubStr.isNotEmpty ? Text(cameraSubStr) : null,
            ),
          if (features.isSupportMapView && _gps != null)
            SizedBox(
              height: 256,
              child: platform.Map(
                center: _gps!,
                zoom: 16,
                onTap: _onMapTap,
              ),
            ),
        ],
      ),
    );
  }

  /// Convert EXIF data to readable format
  void _initMetadata() {
    final exif = widget.file.metadata!.exif!;
    _log.info("[_initMetadata] $exif");

    if (exif.make != null && exif.model != null) {
      _model = "${exif.make} ${exif.model}";
    }
    if (exif.fNumber != null) {
      _fNumber = exif.fNumber!.toDouble();
    }
    if (exif.exposureTime != null) {
      if (exif.exposureTime!.denominator == 1) {
        _exposureTime = exif.exposureTime!.numerator.toString();
      } else {
        _exposureTime = exif.exposureTime.toString();
      }
    }
    if (exif.focalLength != null) {
      _focalLength = exif.focalLength!.toDouble();
    }
    if (exif.isoSpeedRatings != null) {
      _isoSpeedRatings = exif.isoSpeedRatings!;
    }
    if (exif.gpsLatitudeRef != null &&
        exif.gpsLatitude != null &&
        exif.gpsLongitudeRef != null &&
        exif.gpsLongitude != null) {
      final lat = _gpsDmsToDouble(exif.gpsLatitude!) *
          (exif.gpsLatitudeRef == "S" ? -1 : 1);
      final lng = _gpsDmsToDouble(exif.gpsLongitude!) *
          (exif.gpsLongitudeRef == "W" ? -1 : 1);
      _log.fine("GPS: ($lat, $lng)");
      _gps = Tuple2(lat, lng);
    }
  }

  Future<void> _onRemoveFromAlbumPressed(BuildContext context) async {
    assert(widget.album!.provider is AlbumStaticProvider);
    try {
      await NotifiedAction(
        () async {
          final albumRepo = AlbumRepo(AlbumCachedDataSource());
          final newItems =
              AlbumStaticProvider.of(widget.album!).items.where((element) {
            if (element is AlbumFileItem) {
              return element.file.path != widget.file.path;
            } else {
              return true;
            }
          }).toList();
          await UpdateAlbum(albumRepo)(
              widget.account,
              widget.album!.copyWith(
                provider: AlbumStaticProvider(
                  items: newItems,
                ),
              ));
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        null,
        L10n.global().removeSelectedFromAlbumSuccessNotification(1),
        failureText: L10n.global().removeSelectedFromAlbumFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout("[_onRemoveFromAlbumPressed] Failed while updating album", e,
          stackTrace);
    }
  }

  Future<void> _onSetAlbumCoverPressed(BuildContext context) async {
    assert(widget.album != null);
    _log.info(
        "[_onSetAlbumCoverPressed] Set '${widget.file.path}' as album cover for '${widget.album!.name}'");
    try {
      await NotifiedAction(
        () async {
          final albumRepo = AlbumRepo(AlbumCachedDataSource());
          await UpdateAlbum(albumRepo).call(
              widget.account,
              widget.album!.copyWith(
                coverProvider: AlbumManualCoverProvider(
                  coverFile: widget.file,
                ),
              ));
        },
        L10n.global().setAlbumCoverProcessingNotification,
        L10n.global().setAlbumCoverSuccessNotification,
        failureText: L10n.global().setAlbumCoverFailureNotification,
      )();
    } catch (e, stackTrace) {
      _log.shout("[_onSetAlbumCoverPressed] Failed while updating album", e,
          stackTrace);
    }
  }

  void _onAddToAlbumPressed(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlbumPickerDialog(
        account: widget.account,
      ),
    ).then((value) {
      if (value == null) {
        // user cancelled the dialog
      } else if (value is Album) {
        _log.info("[_onAddToAlbumPressed] Album picked: ${value.name}");
        _addToAlbum(value).then((_) {
          SnackBarManager().showSnackBar(SnackBar(
            content:
                Text(L10n.global().addToAlbumSuccessNotification(value.name)),
            duration: k.snackBarDurationNormal,
          ));
        }).catchError((_) {});
      } else {
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().addToAlbumFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
      }
    }).catchError((e, stacktrace) {
      _log.severe(
          "[_onAddToAlbumPressed] Failed while showDialog", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text("${L10n.global().addToAlbumFailureNotification}: "
            "${exception_util.toUserString(e)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  Future<void> _onArchivePressed(BuildContext context) async {
    _log.info("[_onArchivePressed] Archive file: ${widget.file.path}");
    try {
      await NotifiedAction(
        () async {
          final fileRepo = FileRepo(FileCachedDataSource());
          await UpdateProperty(fileRepo)
              .updateIsArchived(widget.account, widget.file, true);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        L10n.global().archiveSelectedProcessingNotification(1),
        L10n.global().archiveSelectedSuccessNotification,
        failureText: L10n.global().archiveSelectedFailureNotification(1),
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onArchivePressed] Failed while archiving file" +
              (shouldLogFileName ? ": ${widget.file.path}" : ""),
          e,
          stackTrace);
    }
  }

  void _onUnarchivePressed(BuildContext context) async {
    _log.info("[_onUnarchivePressed] Unarchive file: ${widget.file.path}");
    try {
      await NotifiedAction(
        () async {
          final fileRepo = FileRepo(FileCachedDataSource());
          await UpdateProperty(fileRepo)
              .updateIsArchived(widget.account, widget.file, false);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        L10n.global().unarchiveSelectedProcessingNotification(1),
        L10n.global().unarchiveSelectedSuccessNotification,
        failureText: L10n.global().unarchiveSelectedFailureNotification(1),
      )();
    } catch (e, stackTrace) {
      _log.shout(
          "[_onUnarchivePressed] Failed while archiving file" +
              (shouldLogFileName ? ": ${widget.file.path}" : ""),
          e,
          stackTrace);
    }
  }

  void _onMapTap() {
    if (platform_k.isAndroid) {
      final intent = AndroidIntent(
        action: "action_view",
        data: Uri.encodeFull("geo:${_gps!.item1},${_gps!.item2}?z=16"),
      );
      intent.launch();
    }
  }

  void _onDateTimeTap(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => PhotoDateTimeEditDialog(initialDateTime: _dateTime),
    ).then((value) async {
      if (value == null || value is! DateTime) {
        return;
      }
      final fileRepo = FileRepo(FileCachedDataSource());
      try {
        await UpdateProperty(fileRepo)
            .updateOverrideDateTime(widget.account, widget.file, value);
        if (mounted) {
          setState(() {
            _dateTime = value;
          });
        }
      } catch (e, stacktrace) {
        _log.shout(
            "[_onDateTimeTap] Failed while updateOverrideDateTime" +
                (shouldLogFileName ? ": ${widget.file.path}" : ""),
            e,
            stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().updateDateTimeFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
      }
    }).catchError((e, stacktrace) {
      _log.shout("[_onDateTimeTap] Failed while showDialog", e, stacktrace);
    });
  }

  static double _gpsDmsToDouble(List<Rational> dms) {
    double product = dms[0].toDouble();
    if (dms.length > 1) {
      product += dms[1].toDouble() / 60;
    }
    if (dms.length > 2) {
      product += dms[2].toDouble() / 3600;
    }
    return product;
  }

  Future<void> _addToAlbum(Album album) async {
    assert(album.provider is AlbumStaticProvider);
    try {
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      final newItem = AlbumFileItem(file: widget.file);
      if (AlbumStaticProvider.of(album)
          .items
          .whereType<AlbumFileItem>()
          .containsIf(newItem, (a, b) => a.file.path == b.file.path)) {
        // already added, do nothing
        _log.info("[_addToAlbum] File already in album: ${widget.file.path}");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(L10n.global().addToAlbumAlreadyAddedNotification),
          duration: k.snackBarDurationNormal,
        ));
        return Future.error(ArgumentError("File already in album"));
      }
      await AddToAlbum(albumRepo)(
          widget.account, album, [AlbumFileItem(file: widget.file)]);
    } catch (e, stacktrace) {
      _log.shout("[_addToAlbum] Failed while updating album", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text("${L10n.global().addToAlbumFailureNotification}: "
            "${exception_util.toUserString(e)}"),
        duration: k.snackBarDurationNormal,
      ));
      rethrow;
    }
  }

  late DateTime _dateTime;
  // EXIF data
  String? _model;
  double? _fNumber;
  String? _exposureTime;
  double? _focalLength;
  int? _isoSpeedRatings;
  Tuple2<double, double>? _gps;

  static final _log =
      Logger("widget.viewer_detail_pane._ViewerDetailPaneState");
}

class _DetailPaneButton extends StatelessWidget {
  const _DetailPaneButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
}

String _byteSizeToString(int byteSize) {
  const units = ["B", "KB", "MB", "GB"];
  var remain = byteSize.toDouble();
  int i = 0;
  while (i < units.length) {
    final next = remain / 1024;
    if (next < 1) {
      break;
    }
    remain = next;
    ++i;
  }
  return "${remain.toStringAsFixed(2)}${units[i]}";
}
