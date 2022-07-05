import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/app_db.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/async_util.dart' as async_util;
import 'package:nc_photos/bloc/list_sharee.dart';
import 'package:nc_photos/bloc/search_suggestion.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/entity/share/data_source.dart';
import 'package:nc_photos/entity/sharee.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/use_case/share_album_with_user.dart';
import 'package:nc_photos/use_case/unshare_album_with_user.dart';
import 'package:nc_photos/widget/album_share_outlier_browser.dart';
import 'package:nc_photos/widget/dialog_scaffold.dart';

class ShareAlbumDialog extends StatefulWidget {
  ShareAlbumDialog({
    Key? key,
    required this.account,
    required this.album,
  })  : assert(album.albumFile != null),
        super(key: key);

  @override
  createState() => _ShareAlbumDialogState();

  final Account account;
  final Album album;
}

class _ShareAlbumDialogState extends State<ShareAlbumDialog> {
  @override
  initState() {
    super.initState();
    _album = widget.album;
    _items = _album.shares
            ?.map((s) =>
                _ShareItem(s.userId, s.displayName ?? s.userId.toString()))
            .toList() ??
        [];
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return AppTheme(
      child: DialogScaffold(
        canPop: _processingSharee.isEmpty,
        body: BlocListener<ListShareeBloc, ListShareeBlocState>(
          bloc: _shareeBloc,
          listener: _onShareeStateChange,
          child: Builder(
            builder: _buildContent,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return SimpleDialog(
      title: Text(L10n.global().shareAlbumDialogTitle),
      children: [
        ..._items.map((i) => _buildItem(context, i)),
        _buildCreateShareItem(context),
      ],
    );
  }

  Widget _buildItem(BuildContext context, _ShareItem share) {
    final isProcessing = _processingSharee.any((s) => s == share.shareWith);
    final Widget trailing;
    if (isProcessing) {
      trailing = Padding(
        padding: const EdgeInsetsDirectional.only(end: 12),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            color: AppTheme.getUnfocusedIconColor(context),
          ),
        ),
      );
    } else {
      trailing = Checkbox(
        value: true,
        onChanged: (_) {},
      );
    }
    return SimpleDialogOption(
      child: ListTile(
        title: Text(share.displayName),
        subtitle: Text(share.shareWith.toString()),
        // pass through the tap event
        trailing: IgnorePointer(
          child: trailing,
        ),
      ),
      onPressed: isProcessing ? () {} : () => _onShareItemPressed(share),
    );
  }

  Widget _buildCreateShareItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: TypeAheadField<Sharee>(
        textFieldConfiguration: TextFieldConfiguration(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: L10n.global().addUserInputHint,
          ),
        ),
        suggestionsCallback: _onSearch,
        itemBuilder: (context, suggestion) => ListTile(
          title: Text(suggestion.label),
          subtitle: Text(suggestion.shareWith.toString()),
        ),
        onSuggestionSelected: _onSearchSuggestionSelected,
        hideOnEmpty: true,
        hideOnLoading: true,
        autoFlipDirection: true,
      ),
    );
  }

  void _onShareeStateChange(BuildContext context, ListShareeBlocState state) {
    if (state is ListShareeBlocSuccess) {
      _transformShareeItems(state.items);
    } else if (state is ListShareeBlocFailure) {
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  Future<void> _onShareItemPressed(_ShareItem share) async {
    setState(() {
      _processingSharee.add(share.shareWith);
    });
    try {
      if (await _removeShare(share)) {
        if (mounted) {
          setState(() {
            _items.remove(share);
            _onShareItemListUpdated();
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingSharee.remove(share.shareWith);
        });
      }
    }
  }

  Future<Iterable<Sharee>> _onSearch(String pattern) async {
    _suggestionBloc.add(SearchSuggestionBlocSearchEvent(pattern.toCi()));
    await Future.delayed(const Duration(milliseconds: 500));
    await async_util
        .wait(() => _suggestionBloc.state is! SearchSuggestionBlocLoading);
    if (_suggestionBloc.state is SearchSuggestionBlocSuccess) {
      return _suggestionBloc.state.results;
    } else {
      return [];
    }
  }

  Future<void> _onSearchSuggestionSelected(Sharee sharee) async {
    _searchController.clear();
    final item = _ShareItem(sharee.shareWith, sharee.label);
    var isGood = false;
    setState(() {
      _items.add(item);
      _onShareItemListUpdated();
      _processingSharee.add(sharee.shareWith);
    });
    try {
      isGood = await _createShare(sharee);
    } finally {
      if (mounted) {
        setState(() {
          if (!isGood) {
            _items.remove(item);
            _onShareItemListUpdated();
          }
          _processingSharee.remove(sharee.shareWith);
        });
      }
    }
  }

  void _onShareItemListUpdated() {
    if (_shareeBloc.state is ListShareeBlocSuccess) {
      _transformShareeItems(_shareeBloc.state.items);
    }
  }

  void _onFixPressed() {
    Navigator.of(context).pushNamed(AlbumShareOutlierBrowser.routeName,
        arguments: AlbumShareOutlierBrowserArguments(widget.account, _album));
  }

  void _transformShareeItems(List<Sharee> sharees) {
    final candidates = sharees
        .where((s) =>
            s.shareWith != widget.account.username &&
            // remove users already shared with
            !_items.any((i) => i.shareWith == s.shareWith))
        .toList();
    _suggestionBloc
        .add(SearchSuggestionBlocUpdateItemsEvent<Sharee>(candidates));
  }

  Future<bool> _createShare(Sharee sharee) async {
    final shareRepo = ShareRepo(ShareRemoteDataSource());
    final albumRepo = AlbumRepo(AlbumCachedDataSource(AppDb()));
    var hasFailure = false;
    try {
      _album = await _editMutex.protect(() async {
        return await ShareAlbumWithUser(shareRepo, albumRepo)(
          widget.account,
          _album,
          sharee,
          onShareFileFailed: (_) {
            hasFailure = true;
          },
        );
      });
    } catch (e, stackTrace) {
      _log.shout(
          "[_createShare] Failed while ShareAlbumWithUser", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      return false;
    }
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(hasFailure
          ? L10n.global()
              .shareAlbumSuccessWithErrorNotification(sharee.shareWith)
          : L10n.global().shareAlbumSuccessNotification(sharee.shareWith)),
      action: hasFailure
          ? SnackBarAction(
              label: L10n.global().fixButtonLabel,
              textColor: Theme.of(context).colorScheme.secondaryVariant,
              onPressed: _onFixPressed,
            )
          : null,
      duration: k.snackBarDurationNormal,
    ));
    return true;
  }

  Future<bool> _removeShare(_ShareItem share) async {
    var hasFailure = false;
    try {
      _album = await _editMutex.protect(() async {
        return await UnshareAlbumWithUser(
            KiwiContainer().resolve<DiContainer>())(
          widget.account,
          _album,
          share.shareWith,
          onUnshareFileFailed: (_) {
            hasFailure = true;
          },
        );
      });
    } catch (e, stackTrace) {
      _log.shout(
          "[_removeShare] Failed while UnshareAlbumWithUser", e, stackTrace);
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(e)),
        duration: k.snackBarDurationNormal,
      ));
      return false;
    }
    SnackBarManager().showSnackBar(SnackBar(
      content: Text(hasFailure
          ? L10n.global()
              .unshareAlbumSuccessWithErrorNotification(share.shareWith)
          : L10n.global().unshareAlbumSuccessNotification(share.shareWith)),
      action: hasFailure
          ? SnackBarAction(
              label: L10n.global().fixButtonLabel,
              textColor: Theme.of(context).colorScheme.secondaryVariant,
              onPressed: _onFixPressed,
            )
          : null,
      duration: k.snackBarDurationNormal,
    ));
    return true;
  }

  Future<void> _initBloc() async {
    if (_shareeBloc.state is ListShareeBlocSuccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _onShareeStateChange(context, _shareeBloc.state);
        });
      });
    } else {
      _log.info("[_initBloc] Initialize bloc");
      _shareeBloc.add(ListShareeBlocQuery(widget.account));
    }
  }

  late final _shareeBloc = ListShareeBloc.of(widget.account);
  final _suggestionBloc = SearchSuggestionBloc<Sharee>(
    itemToKeywords: (item) => [item.shareWith, item.label.toCi()],
  );

  late Album _album;
  final _editMutex = Mutex();
  late final List<_ShareItem> _items;
  final _processingSharee = <CiString>[];
  final _searchController = TextEditingController();

  static final _log =
      Logger("widget.share_album_dialog._ShareAlbumDialogState");
}

class _ShareItem {
  _ShareItem(this.shareWith, this.displayName);

  final CiString shareWith;
  final String displayName;
}
