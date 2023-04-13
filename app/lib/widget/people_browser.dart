import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:kiwi/kiwi.dart';
import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api_util.dart' as api_util;
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/bloc/list_person.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/collection/builder.dart';
import 'package:nc_photos/entity/person.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/exception_util.dart' as exception_util;
import 'package:nc_photos/k.dart' as k;
import 'package:nc_photos/snack_bar_manager.dart';
import 'package:nc_photos/theme.dart';
import 'package:nc_photos/widget/collection_browser.dart';
import 'package:nc_photos/widget/collection_list_item.dart';
import 'package:np_codegen/np_codegen.dart';

part 'people_browser.g.dart';

class PeopleBrowserArguments {
  const PeopleBrowserArguments(this.account);

  final Account account;
}

/// Show a list of all people associated with this account
class PeopleBrowser extends StatefulWidget {
  static const routeName = "/people-browser";

  static Route buildRoute(PeopleBrowserArguments args) => MaterialPageRoute(
        builder: (context) => PeopleBrowser.fromArgs(args),
      );

  const PeopleBrowser({
    Key? key,
    required this.account,
  }) : super(key: key);

  PeopleBrowser.fromArgs(PeopleBrowserArguments args, {Key? key})
      : this(
          key: key,
          account: args.account,
        );

  @override
  createState() => _PeopleBrowserState();

  final Account account;
}

@npLog
class _PeopleBrowserState extends State<PeopleBrowser> {
  @override
  initState() {
    super.initState();
    _initBloc();
  }

  @override
  build(BuildContext context) {
    return Scaffold(
      body: BlocListener<ListPersonBloc, ListPersonBlocState>(
        bloc: _bloc,
        listener: (context, state) => _onStateChange(context, state),
        child: BlocBuilder<ListPersonBloc, ListPersonBlocState>(
          bloc: _bloc,
          builder: (context, state) => _buildContent(context, state),
        ),
      ),
    );
  }

  void _initBloc() {
    if (_bloc.state is ListPersonBlocInit) {
      _log.info("[_initBloc] Initialize bloc");
    } else {
      // process the current state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _onStateChange(context, _bloc.state);
          });
        }
      });
    }
    _reqQuery();
  }

  Widget _buildContent(BuildContext context, ListPersonBlocState state) {
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            _buildAppBar(context),
            if (state is ListPersonBlocLoading)
              const SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.center,
                  child: LinearProgressIndicator(),
                ),
              ),
            SliverStaggeredGrid.extentBuilder(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              itemCount: _items.length,
              itemBuilder: _buildItem,
              staggeredTileBuilder: (_) => const StaggeredTile.count(1, 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      title: Text(L10n.global().collectionPeopleLabel),
      floating: true,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = _items[index];
    return item.buildWidget(context);
  }

  void _onStateChange(BuildContext context, ListPersonBlocState state) {
    if (state is ListPersonBlocInit) {
      _items = [];
    } else if (state is ListPersonBlocSuccess ||
        state is ListPersonBlocLoading) {
      _transformItems(state.items);
    } else if (state is ListPersonBlocFailure) {
      _transformItems(state.items);
      try {
        final e = state.exception as ApiException;
        if (e.response.statusCode == 404) {
          // face recognition app probably not installed, ignore
          return;
        }
      } catch (_) {}
      SnackBarManager().showSnackBar(SnackBar(
        content: Text(exception_util.toUserString(state.exception)),
        duration: k.snackBarDurationNormal,
      ));
    }
  }

  void _onItemTap(Person person) {
    Navigator.pushNamed(
      context,
      CollectionBrowser.routeName,
      arguments: CollectionBrowserArguments(
        CollectionBuilder.byPerson(widget.account, person),
      ),
    );
  }

  void _transformItems(List<Person> items) {
    _items = items
        .sorted((a, b) {
          final countCompare = b.count.compareTo(a.count);
          if (countCompare == 0) {
            return a.name.compareTo(b.name);
          } else {
            return countCompare;
          }
        })
        .map((e) => _PersonListItem(
              account: widget.account,
              name: e.name,
              faceUrl: api_util.getFacePreviewUrl(widget.account, e.thumbFaceId,
                  size: k.faceThumbSize),
              onTap: () => _onItemTap(e),
            ))
        .toList();
  }

  void _reqQuery() {
    _bloc.add(ListPersonBlocQuery(widget.account));
  }

  late final _bloc = ListPersonBloc(KiwiContainer().resolve<DiContainer>());

  var _items = <_ListItem>[];
}

abstract class _ListItem {
  _ListItem({
    this.onTap,
  });

  Widget buildWidget(BuildContext context);

  final VoidCallback? onTap;
}

class _PersonListItem extends _ListItem {
  _PersonListItem({
    required this.account,
    required this.name,
    required this.faceUrl,
    VoidCallback? onTap,
  }) : super(onTap: onTap);

  @override
  buildWidget(BuildContext context) => CollectionListSmall(
        account: account,
        label: name,
        coverUrl: faceUrl,
        fallbackBuilder: (context) => Icon(
          Icons.person,
          color: Theme.of(context).listPlaceholderForegroundColor,
        ),
        onTap: onTap,
      );

  final Account account;
  final String name;
  final String faceUrl;
}
