import 'package:np_common/size.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

abstract class Method {
  Future<void> prepareResource({void Function(double progress)? onProgress});

  Future<void> cleanResource();

  Future<bool> isResourceReady();

  SizeInt getMaxSrcSize();

  Future<Rgb8Image?> apply(Rgb8Image src);
}
