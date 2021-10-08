import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/cache_manager_util.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/remove_share.dart';
import 'package:path/path.dart' as path;

class SharedFileViewerArguments {
  SharedFileViewerArguments(this.account, this.file, this.shares);

  final Account account;
  final File file;
  final List<Share> shares;
}

/// Handle shares associated with a [File]
class SharedFileViewer extends StatefulWidget {
  static const routeName = "/shared-file-viewer";

  static Route buildRoute(SharedFileViewerArguments args) => MaterialPageRoute(
        builder: (context) => SharedFileViewer.fromArgs(args),
      );

  const SharedFileViewer({
    Key? key,
    required this.account,
    required this.file,
    required this.shares,
  }) : super(key: key);

  SharedFileViewer.fromArgs(SharedFileViewerArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
          file: args.file,
          shares: args.shares,
        );

  @override
  createState() => _SharedFileViewerState();

  final Account account;
  final File file;
  final List<Share> shares;
}

class _SharedFileViewerState extends State<SharedFileViewer> {
  @override
  build(BuildContext context) {
    return AppTheme(
      child: Scaffold(
        body: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final previewUrl = api_util.getFilePreviewUrl(
      widget.account,
      widget.file,
      width: k.photoLargeSize,
      height: k.photoLargeSize,
      a: true,
    );
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text(path.withoutExtension(widget.file.filename)),
          pinned: true,
        ),
        if (widget.file.isCollection != true)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 256,
              child: FittedBox(
                alignment: Alignment.center,
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: CachedNetworkImage(
                  cacheManager: CoverCacheManager.inst,
                  imageUrl: previewUrl,
                  httpHeaders: {
                    "Authorization":
                        Api.getAuthorizationHeaderValue(widget.account),
                  },
                  fadeInDuration: const Duration(),
                  filterQuality: FilterQuality.high,
                  errorWidget: (context, url, error) {
                    // just leave it empty
                    return Container();
                  },
                  imageRenderMethodForWeb: ImageRenderMethodForWeb.HttpGet,
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              L10n.global().locationLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: ListTile(
            title: Text(widget.file.strippedPath),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              L10n.global().sharedWithLabel,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildShareItem(context, _shares[index]),
            childCount: _shares.length,
          ),
        ),
      ],
    );
  }

  Widget _buildShareItem(BuildContext context, Share share) {
    final dateStr = DateFormat(DateFormat.YEAR_ABBR_MONTH_DAY,
            Localizations.localeOf(context).languageCode)
        .format(share.stime.toLocal());
    return ListTile(
      title: Text(_getShareTitle(share)),
      subtitle: Text(dateStr),
      leading: SizedBox(
        height: double.infinity,
        child: Icon(_getShareIcon(share)),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (share.shareType == ShareType.publicLink)
            IconButton(
              onPressed: () => _onItemCopyPressed(share),
              icon: Tooltip(
                message: MaterialLocalizations.of(context).copyButtonLabel,
                child: const Icon(Icons.copy_outlined),
              ),
            ),
          PopupMenuButton<_ItemMenuOption>(
            tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _ItemMenuOption.unshare,
                child: Text(L10n.global().unshareTooltip),
              ),
            ],
            onSelected: (option) =>
                _onItemMenuOptionSelected(context, share, option),
          ),
        ],
      ),
    );
  }

  Future<void> _onItemCopyPressed(Share share) async {
    await Clipboard.setData(ClipboardData(text: share.url!));
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(L10n.global().linkCopiedNotification),
      duration: k.snackBarDurationNormal,
    ));
  }

  void _onItemMenuOptionSelected(
      BuildContext context, Share share, _ItemMenuOption option) {
    switch (option) {
      case _ItemMenuOption.unshare:
        _onItemUnsharePressed(context, share);
        break;
    }
  }

  Future<void> _onItemUnsharePressed(BuildContext context, Share share) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    try {
      await RemoveShare(shareRepo)(widget.account, share);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(L10n.global().unshareSuccessNotification),
        duration: k.snackBarDurationNormal,
      ));
      if (_shares.length == 1) {
        // removing last share
        Navigator.of(context).pop();
      } else {
        setState(() {
          _shares.remove(share);
        });
      }
    } catch (e, stackTrace) {
      _log.shout(
          "[_onItemUnsharePressed] Failed while RemoveShare", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  IconData? _getShareIcon(Share share) {
    switch (share.shareType) {
      case ShareType.user:
      case ShareType.email:
      case ShareType.federatedCloudShare:
        return Icons.person_outlined;
      case ShareType.group:
      case ShareType.circle:
        return Icons.group_outlined;
      case ShareType.publicLink:
        return Icons.link_outlined;
      case ShareType.talk:
        return Icons.sms_outlined;
      default:
        return null;
    }
  }

  String _getShareTitle(Share share) {
    if (share.shareType == ShareType.publicLink) {
      if (share.url!.startsWith(widget.account.url)) {
        return share.url!.substring(widget.account.url.length);
      } else {
        return share.url!;
      }
    } else {
      return share.shareWithDisplayName;
    }
  }

  late final List<Share> _shares = List.of(widget.shares);

  static final _log =
      Logger("widget.shared_file_viewer._SharedFileViewerState");
}

enum _ItemMenuOption {
  unshare,
}
