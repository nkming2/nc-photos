import 'package:logging/logging.dart';
import 'package:nc_photos/account.dart';
import 'package:nc_photos/db/entity_converter.dart';
import 'package:nc_photos/entity/image_location/repo.dart';
import 'package:np_async/np_async.dart';
import 'package:np_codegen/np_codegen.dart';
import 'package:np_db/np_db.dart';

part 'data_source.g.dart';

@npLog
class ImageLocationNpDbDataSource implements ImageLocationDataSource {
  const ImageLocationNpDbDataSource(this.db);

  @override
  Future<List<ImageLatLng>> getLocations(Account account) async {
    _log.info("[getLocations]");
    final results = await db.getImageLatLngWithFileIds(account: account.toDb());
    return results.computeAll(DbImageLatLngConverter.fromDb);
  }

  final NpDb db;
}
