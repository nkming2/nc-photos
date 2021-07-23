import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/bloc/list_importable_album.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_util.dart' as file_util;
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/iterable_extension.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/create_album.dart';
import 'package:nc_photos/use_case/populate_album.dart';
import 'package:nc_photos/use_case/update_dynamic_album_cover.dart';
import 'package:nc_photos/use_case/update_dynamic_album_time.dart';
import 'package:nc_photos/widget/processing_dialog.dart';
import 'package:path/path.dart' as path;

class AlbumImporterArguments {
  AlbumImporterArguments(this.account);

  final Account account;
}

class AlbumImporter extends StatefulWidget {
  static const routeName = "/album-importer";

  static Route buildRoute(AlbumImporterArguments args) => MaterialPageRoute(
        builder: (context) => AlbumImporter.fromArgs(args),
      );

  AlbumImporter({
    Key? key,
    required this.account,
  }) : super(key: key);

  AlbumImporter.fromArgs(AlbumImporterArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _AlbumImporterState();

  final Account account;
}

class _AlbumImporterState extends State<AlbumImporter> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body:
            BlocListener<ListImportableAlbumBloc, ListImportableAlbumBlocState>(
          bloc: _bloc,
          listener: (context, state) => _onStateChange(context, state),
          child: BlocBuilder<ListImportableAlbumBloc,
              ListImportableAlbumBlocState>(
            bloc: _bloc,
            builder: (context, state) => _buildContent(context, state),
          ),
        ),
      ),
    );
  }

  void _initBloc() {
    _log.info("[_initBloc] Initialize bloc");
    _bloc = ListImportableAlbumBloc();
    _bloc.add(ListImportableAlbumBlocQuery(
        widget.account,
        widget.account.roots
            .map((e) => File(
                path:
                    "${api_util.getWebdavRootUrlRelative(widget.account)}/$e"))
            .toList()));
  }

  Widget _buildContent(
      BuildContext context, ListImportableAlbumBlocState state) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.albumImporterHeaderText,
                  style: Theme.of(context).textTheme.headline5,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Text(
                    AppLocalizations.of(context)!.albumImporterSubHeaderText,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: _buildList(context, state),
                ),
                if (state is ListImportableAlbumBlocLoading)
                  Align(
                    alignment: Alignment.topCenter,
                    child: const LinearProgressIndicator(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      Text(MaterialLocalizations.of(context).cancelButtonLabel),
                ),
                ElevatedButton(
                  onPressed: () => _onImportPressed(context),
                  child: Text(AppLocalizations.of(context)!.importButtonLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, ListImportableAlbumBlocState state) {
    return Theme(
      data: Theme.of(context).copyWith(
        accentColor: AppTheme.getOverscrollIndicatorColor(context),
      ),
      child: ListView.separated(
        itemBuilder: (context, index) =>
            _buildItem(context, _backingFiles[index]),
        separatorBuilder: (context, index) => const Divider(),
        itemCount: _backingFiles.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, File file) {
    final isPicked = _picks.containsIdentical(file);
    final onTap = () {
      setState(() {
        if (isPicked) {
          _picks.removeWhere((p) => identical(p, file));
        } else {
          _picks.add(file);
        }
      });
    };
    return ListTile(
      dense: true,
      leading: IconButton(
        icon: AnimatedSwitcher(
          duration: k.animationDurationShort,
          transitionBuilder: (child, animation) =>
              ScaleTransition(child: child, scale: animation),
          child: Icon(
            isPicked ? Icons.check_box : Icons.check_box_outline_blank,
            key: ValueKey(isPicked),
          ),
        ),
        onPressed: onTap,
      ),
      title: Text(path.basename(file.path)),
      subtitle: Text(file.strippedPath),
      onTap: onTap,
    );
  }

  void _onStateChange(
      BuildContext context, ListImportableAlbumBlocState state) {
    if (state is ListImportableAlbumBlocSuccess ||
        state is ListImportableAlbumBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListImportableAlbumBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception, context)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onImportPressed(BuildContext context) async {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => ProcessingDialog(
          text: AppLocalizations.of(context)!.albumImporterProgressText),
    );
    try {
      await _createAllAlbums(context);
    } finally {
      // make sure we dismiss the dialog in any cases
      Navigator.of(context).pop();
    }
    Navigator.of(context).pop();
  }

  Future<void> _createAllAlbums(BuildContext context) async {
    for (final p in _picks) {
      try {
        var album = Album(
          name: path.basename(p.path),
          provider: AlbumDirProvider(
            dirs: [p],
          ),
          coverProvider: AlbumAutoCoverProvider(),
          sortProvider: AlbumTimeSortProvider(isAscending: false),
        );
        _log.info("[_onImportPressed] Creating dir album: $album");

        final items = await PopulateAlbum()(widget.account, album);
        final sortedFiles = items
            .whereType<AlbumFileItem>()
            .map((e) => e.file)
            .where((element) => file_util.isSupportedFormat(element))
            .sorted(compareFileDateTimeDescending);
        album =
            UpdateDynamicAlbumCover().updateWithSortedFiles(album, sortedFiles);
        album =
            UpdateDynamicAlbumTime().updateWithSortedFiles(album, sortedFiles);

        final albumRepo = AlbumRepo(AlbumCachedDataSource());
        await CreateAlbum(albumRepo)(widget.account, album);
      } catch (e, stacktrace) {
        _log.shout(
            "[_createAllAlbums] Failed creating dir album", e, stacktrace);
        SnackBarManager().showSnackBar(SnackBar(
          content: Text(exception_util.toUserString(e, context)),
          duration: k.snackBarDurationNormal,
        ));
      }
    }
  }

  void _transformItems(List<ListImportableAlbumBlocItem> items) {
    _backingFiles = items
        .sorted((a, b) => b.photoCount - a.photoCount)
        .map((e) => e.file)
        .toList();
  }

  late ListImportableAlbumBloc _bloc;

  var _backingFiles = <File>[];
  final _picks = <File>[];

  static final _log = Logger("widget.album_importer._AlbumImporterState");
}
