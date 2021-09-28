import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/api/api.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/share.dart';
import 'package:nc_photos/exception.dart';
import 'package:nc_photos/type.dart';

class ShareRemoteDataSource implements ShareDataSource {
  @override
  list(Account account, File file) async {
    _log.info("[list] ${file.path}");
    final response = await Api(account).ocs().filesSharing().shares().get(
          path: file.strippedPath,
        );
    return _onListResult(response);
  }

  @override
  listDir(Account account, File dir) async {
    _log.info("[listDir] ${dir.path}");
    final response = await Api(account).ocs().filesSharing().shares().get(
          path: dir.strippedPath,
          subfiles: true,
        );
    return _onListResult(response);
  }

  @override
  create(Account account, File file, String shareWith) async {
    _log.info("[create] Share '${file.path}' with '$shareWith'");
    final response = await Api(account).ocs().filesSharing().shares().post(
          path: file.strippedPath,
          shareType: ShareType.user.toValue(),
          shareWith: shareWith,
        );
    if (!response.isGood) {
      _log.severe("[create] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    final JsonObj dataJson = json["ocs"]["data"];
    return _ShareParser().parseSingle(dataJson);
  }

  @override
  delete(Account account, Share share) async {
    _log.info("[delete] $share");
    final response =
        await Api(account).ocs().filesSharing().share(share.id).delete();
    if (!response.isGood) {
      _log.severe("[delete] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }
  }

  List<Share> _onListResult(Response response) {
    if (!response.isGood) {
      _log.severe("[_onListResult] Failed requesting server: $response");
      throw ApiException(
          response: response,
          message: "Failed communicating with server: ${response.statusCode}");
    }

    final json = jsonDecode(response.body);
    final List<JsonObj> dataJson = json["ocs"]["data"].cast<JsonObj>();
    return _ShareParser().parseList(dataJson);
  }

  static final _log = Logger("entity.share.data_source.ShareRemoteDataSource");
}

class _ShareParser {
  List<Share> parseList(List<JsonObj> jsons) {
    final product = <Share>[];
    for (final j in jsons) {
      try {
        product.add(parseSingle(j));
      } catch (e) {
        _log.severe("[parseList] Failed parsing json: ${jsonEncode(j)}", e);
      }
    }
    return product;
  }

  Share parseSingle(JsonObj json) {
    final shareType = ShareTypeExtension.fromValue(json["share_type"]);
    return Share(
      id: json["id"],
      path: json["path"],
      shareType: shareType,
      shareWith: json["share_with"],
      shareWithDisplayName: json["share_with_displayname"],
    );
  }

  static final _log = Logger("entity.share.data_source._ShareParser");
}
