import 'dart:math';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/entity/any_file/any_file.dart';
import 'package:nc_photos/flutter_util.dart';
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/widget/viewer/viewer.dart';
import 'package:np_collection/np_collection.dart';
import 'package:np_log/np_log.dart';

part 'anyfile_list_viewer.g.dart';

class AnyFileListViewerArguments {
  const AnyFileListViewerArguments({
    required this.files,
    this.initialIndex = 0,
  });

  final List<AnyFile> files;
  final int initialIndex;
}

class AnyFileListViewer extends StatelessWidget {
  static const routeName = "/any-file-list-viewer";

  static Route buildRoute(
    AnyFileListViewerArguments args,
    RouteSettings settings,
  ) => CustomizableMaterialPageRoute(
    transitionDuration: k.heroDurationNormal,
    reverseTransitionDuration: k.heroDurationNormal,
    builder: (_) => AnyFileListViewer.fromArgs(args),
    settings: settings,
  );

  const AnyFileListViewer({
    super.key,
    required this.files,
    this.initialIndex = 0,
  });

  AnyFileListViewer.fromArgs(AnyFileListViewerArguments args, {Key? key})
    : this(key: key, files: args.files, initialIndex: args.initialIndex);

  @override
  Widget build(BuildContext context) {
    return Viewer(
      contentProvider: _AnyFileListViewerContentProvider(
        files: files,
        initialIndex: initialIndex,
      ),
      initialFile: files[initialIndex],
    );
  }

  final List<AnyFile> files;
  final int initialIndex;
}

@npLog
class _AnyFileListViewerContentProvider implements ViewerContentProvider {
  const _AnyFileListViewerContentProvider({
    required this.files,
    required this.initialIndex,
  });

  @override
  Future<ViewerContentProviderResult> getFiles(
    ViewerPositionInfo at,
    int count,
  ) async {
    final pageIndex = _toAbsolutePageIndex(at.pageIndex);
    if (count > 0) {
      final results = files.pySlice(pageIndex + 1, pageIndex + 1 + count);
      return ViewerContentProviderResult(files: results);
    } else {
      final results = files.pySlice(max(pageIndex - count.abs(), 0), pageIndex);
      return ViewerContentProviderResult(files: results.reversed.toList());
    }
  }

  @override
  Future<AnyFile> getFile(int page, String afId) async {
    return files[page];
  }

  @override
  void notifyFileRemoved(int page, AnyFile file) {
    if (files[page].id != file.id) {
      _log.warning(
        "[notifyFileRemoved] Removed file does not match record, page: $page, expected: ${files[page].id}, actual: ${file.id}",
      );
    }
    files.removeAt(page);
  }

  @override
  Future<List<String>> listAfIds() async {
    return files.map((e) => e.id).toList();
  }

  int _toAbsolutePageIndex(int relativePageIndex) {
    return relativePageIndex + initialIndex;
  }

  final List<AnyFile> files;
  final int initialIndex;
}
