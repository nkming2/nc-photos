import 'dart:io';

import 'package:android_intent/android_intent.dart';
import 'package:exifdart/exifdart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/double_extension.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/platform/features.dart' as features;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove.dart';
import 'package:nc_photos/use_case/update_album.dart';
import 'package:nc_photos/widget/album_picker_dialog.dart';
import 'package:path/path.dart';

class ViewerDetailPane extends StatefulWidget {
  const ViewerDetailPane({
    Key key,
    @required this.account,
    @required this.file,
  }) : super(key: key);

  @override
  createState() => _ViewerDetailPaneState();

  final Account account;
  final File file;
}

class _ViewerDetailPaneState extends State<ViewerDetailPane> {
  @override
  initState() {
    super.initState();

    if (widget.file.metadata == null) {
      _log.info("[initState] Metadata missing in File");
    } else {
      _log.info("[initState] Metadata exists in File");
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        _updateMetadata(widget.file.metadata.imageWidth,
            widget.file.metadata.imageHeight, widget.file.metadata.exif);
      });
    }
  }

  @override
  build(BuildContext context) {
    final dateTime = (_dateTime ?? widget.file.lastModified).toLocal();
    final dateStr = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY).format(dateTime);
    final timeStr = DateFormat(DateFormat.HOUR_MINUTE).format(dateTime);

    String sizeSubStr = "";
    const space = "    ";
    if (_width != null && _height != null) {
      final pixelCount = _width * _height;
      if (pixelCount >= 500000) {
        final mpCount = pixelCount / 1000000.0;
        sizeSubStr += AppLocalizations.of(context)
            .megapixelCount(mpCount.toStringAsFixed(1));
        sizeSubStr += space;
      }
      sizeSubStr += _byteSizeToString(widget.file.contentLength);
    }

    String cameraSubStr = "";
    if (_fNumber != null) {
      cameraSubStr += "f/${_fNumber.toStringAsFixed(1)}$space";
    }
    if (_exposureTime != null) {
      cameraSubStr +=
          AppLocalizations.of(context).secondCountSymbol(_exposureTime);
      cameraSubStr += space;
    }
    if (_focalLength != null) {
      cameraSubStr += AppLocalizations.of(context)
          .millimeterCountSymbol(_focalLength.toStringAsFixedTruncated(2));
      cameraSubStr += space;
    }
    if (_isoSpeedRatings != null) {
      cameraSubStr += "ISO$_isoSpeedRatings$space";
    }
    cameraSubStr = cameraSubStr.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _DetailPaneButton(
              icon: Icons.playlist_add_outlined,
              label: AppLocalizations.of(context).addToAlbumTooltip,
              onPressed: () => _onAddToAlbumPressed(context),
            ),
            _DetailPaneButton(
              icon: Icons.delete_outline,
              label: AppLocalizations.of(context).deleteTooltip,
              onPressed: () => _onDeletePressed(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: const Divider(),
        ),
        ListTile(
          leading: Icon(
            Icons.image_outlined,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          title: Text(basenameWithoutExtension(widget.file.path)),
          subtitle: Text(widget.file.strippedPath),
        ),
        ListTile(
          leading: Icon(
            Icons.calendar_today_outlined,
            color: AppTheme.getSecondaryTextColor(context),
          ),
          title: Text("$dateStr $timeStr"),
        ),
        if (_width != null && _height != null)
          ListTile(
            leading: Icon(
              Icons.aspect_ratio,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            title: Text("$_width x $_height"),
            subtitle: Text(sizeSubStr),
          )
        else
          ListTile(
            leading: Icon(
              Icons.aspect_ratio,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            title: Text(_byteSizeToString(widget.file.contentLength)),
          ),
        if (_model != null)
          ListTile(
            leading: Icon(
              Icons.camera_outlined,
              color: AppTheme.getSecondaryTextColor(context),
            ),
            title: Text(_model),
            subtitle: cameraSubStr.isNotEmpty ? Text(cameraSubStr) : null,
          ),
        if (features.isSupportMapView && _gps != null)
          SizedBox(
            height: 256,
            child: GoogleMap(
              compassEnabled: false,
              mapToolbarEnabled: false,
              rotateGesturesEnabled: false,
              scrollGesturesEnabled: false,
              zoomControlsEnabled: false,
              zoomGesturesEnabled: false,
              tiltGesturesEnabled: false,
              myLocationButtonEnabled: false,
              buildingsEnabled: false,
              // liteModeEnabled: true,
              initialCameraPosition: CameraPosition(
                target: _gps,
                zoom: 16,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("at"),
                  position: _gps,
                  // for some reason, GoogleMap's onTap is not triggered if
                  // tapped on top of the marker
                  onTap: _onMapTap,
                ),
              },
              onTap: (_) => _onMapTap(),
            ),
          ),
      ],
    );
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
        _addToAlbum(context, value).then((_) {
          SnackBarManager().showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)
                .addToAlbumSuccessNotification(value.name)),
            duration: k.snackBarDurationNormal,
          ));
        }).catchError((_) {});
      } else {
        SnackBarManager().showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context).addToAlbumFailureNotification),
          duration: k.snackBarDurationNormal,
        ));
      }
    }).catchError((e, stacktrace) {
      _log.severe(
          "[_onAddToAlbumPressed] Failed while showDialog", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).addToAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    });
  }

  void _onDeletePressed(BuildContext context) async {
    _log.info("[_onDeletePressed] Removing file: ${widget.file.path}");
    var controller = SnackBarManager().showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context).deleteProcessingNotification),
      duration: k.snackBarDurationShort,
    ));
    controller?.closed?.whenComplete(() {
      controller = null;
    });
    try {
      await Remove(FileRepo(FileCachedDataSource()),
          AlbumRepo(AlbumCachedDataSource()))(widget.account, widget.file);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context).deleteSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
      Navigator.of(context).pop();
    } catch (e, stacktrace) {
      _log.severe("[_onDeletePressed] Failed while remove: ${widget.file.path}",
          e, stacktrace);
      controller?.close();
      SnackBarManager().showSnackBar(SnackBar(
        content:
            Text("${AppLocalizations.of(context).deleteFailureNotification}: "
                "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onMapTap() {
    if (Platform.isAndroid) {
      final intent = AndroidIntent(
        action: "action_view",
        data: Uri.encodeFull("geo:${_gps.latitude},${_gps.longitude}?z=16"),
      );
      intent.launch();
    }
  }

  void _updateMetadata(int imageWidth, int imageHeight, Exif exif) {
    if (imageWidth != null && imageHeight != null) {
      setState(() {
        _width = imageWidth;
        _height = imageHeight;
      });
    }
    if (exif != null) {
      _updateMetadataExif(exif);
    }
  }

  void _updateMetadataExif(Exif exif) {
    _log.info("[_updateMetadataExif] $exif");
    if (exif.dateTimeOriginal != null) {
      setState(() {
        _dateTime = exif.dateTimeOriginal;
      });
    }
    if (exif.make != null && exif.model != null) {
      setState(() {
        _model = "${exif.make} ${exif.model}";
      });
    }
    if (exif.fNumber != null) {
      setState(() {
        _fNumber = exif.fNumber.toDouble();
      });
    }
    if (exif.exposureTime != null) {
      setState(() {
        if (exif.exposureTime.denominator == 1) {
          _exposureTime = exif.exposureTime.numerator.toString();
        } else {
          _exposureTime = exif.exposureTime.toString();
        }
      });
    }
    if (exif.focalLength != null) {
      setState(() {
        _focalLength = exif.focalLength.toDouble();
      });
    }
    if (exif.isoSpeedRatings != null) {
      setState(() {
        _isoSpeedRatings = exif.isoSpeedRatings;
      });
    }
    if (exif.gpsLatitudeRef != null &&
        exif.gpsLatitude != null &&
        exif.gpsLongitudeRef != null &&
        exif.gpsLongitude != null) {
      final lat = _gpsDmsToDouble(exif.gpsLatitude) *
          (exif.gpsLatitudeRef == "S" ? -1 : 1);
      final lng = _gpsDmsToDouble(exif.gpsLongitude) *
          (exif.gpsLongitudeRef == "W" ? -1 : 1);
      _log.fine("GPS: ($lat, $lng)");
      setState(() {
        _gps = LatLng(lat, lng);
      });
    }
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

  Future<void> _addToAlbum(BuildContext context, Album album) async {
    try {
      final albumRepo = AlbumRepo(AlbumCachedDataSource());
      final newItem = AlbumFileItem(file: widget.file);
      if (album.items
          .whereType<AlbumFileItem>()
          .containsIf(newItem, (a, b) => a.file.path == b.file.path)) {
        // already added, do nothing
        _log.info("[_addToAlbum] File already in album: ${widget.file.path}");
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(
              "${AppLocalizations.of(context).addToAlbumAlreadyAddedNotification}"),
          duration: k.snackBarDurationNormal,
        ));
        return Future.error(ArgumentError("File already in album"));
      }
      await UpdateAlbum(albumRepo)(
          widget.account,
          album.copyWith(
            items: [...album.items, AlbumFileItem(file: widget.file)],
          ));
    } catch (e, stacktrace) {
      _log.severe("[_addToAlbum] Failed while updating album", e, stacktrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(
            "${AppLocalizations.of(context).addToAlbumFailureNotification}: "
            "${exception_util.toUserString(e, context)}"),
        duration: k.snackBarDurationNormal,
      ));
      rethrow;
    }
  }

  // metadata
  int _width;
  int _height;
  // EXIF data
  DateTime _dateTime;
  String _model;
  double _fNumber;
  String _exposureTime;
  double _focalLength;
  int _isoSpeedRatings;
  LatLng _gps;

  static final _log =
      Logger("widget.viewer_detail_pane._ViewerDetailPaneState");
}

class _DetailPaneButton extends StatelessWidget {
  const _DetailPaneButton({Key key, this.icon, this.label, this.onPressed})
      : super(key: key);

  @override
  build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                color: AppTheme.getPrimaryTextColor(context),
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
  final VoidCallback onPressed;
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
