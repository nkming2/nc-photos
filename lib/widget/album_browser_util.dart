import 'package:flutter/widgets.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/widget/album_browser.dart';
import 'package:nc_photos/widget/dynamic_album_browser.dart';

/// Push the corresponding browser route for this album
Future<void> push(BuildContext context, Account account, Album album) {
  if (album.provider is AlbumStaticProvider) {
    return Navigator.of(context).pushNamed(AlbumBrowser.routeName,
        arguments: AlbumBrowserArguments(account, album));
  } else {
    return Navigator.of(context).pushNamed(DynamicAlbumBrowser.routeName,
        arguments: DynamicAlbumBrowserArguments(account, album));
  }
}

/// Push the corresponding browser route for this album and replace the current
/// route
Future<void> pushReplacement(
    BuildContext context, Account account, Album album) {
  if (album.provider is AlbumStaticProvider) {
    return Navigator.of(context).pushReplacementNamed(AlbumBrowser.routeName,
        arguments: AlbumBrowserArguments(account, album));
  } else {
    return Navigator.of(context).pushReplacementNamed(
        DynamicAlbumBrowser.routeName,
        arguments: DynamicAlbumBrowserArguments(account, album));
  }
}
