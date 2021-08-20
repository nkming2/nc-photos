import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/widget/album_browser.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';

/// Open the corresponding browser for this album
Future<void> open(BuildContext context, Account account, Album album) {
  if (album.provider is AlbumStaticProvider) {
    return Navigator.of(context).pushNamed(AlbumBrowser.routeName,
        arguments: AlbumBrowserArguments(account, album));
  } else {
    return Navigator.of(context).pushNamed(DynamicAlbumBrowser.routeName,
        arguments: DynamicAlbumBrowserArguments(account, album));
  }
}
