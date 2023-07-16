import 'package:nc_photos/account.dart';
import 'package:nc_photos/di_container.dart';
import 'package:nc_photos/entity/recognize_face.dart';
import 'package:nc_photos/entity/recognize_face_item.dart';
import 'package:np_common/type.dart';

class ListRecognizeFaceItem {
  const ListRecognizeFaceItem(this._c);

  /// List all [RecognizeFaceItem]s belonging to [face]
  Stream<List<RecognizeFaceItem>> call(Account account, RecognizeFace face) =>
      _c.recognizeFaceRepo.getItems(account, face);

  final DiContainer _c;
}

class ListMultipleRecognizeFaceItem {
  const ListMultipleRecognizeFaceItem(this._c);

  /// List all [RecognizeFaceItem]s belonging to each face
  Stream<Map<RecognizeFace, List<RecognizeFaceItem>>> call(
    Account account,
    List<RecognizeFace> faces, {
    ErrorWithValueHandler<RecognizeFace>? onError,
  }) =>
      _c.recognizeFaceRepo.getMultiFaceItems(account, faces, onError: onError);

  final DiContainer _c;
}
