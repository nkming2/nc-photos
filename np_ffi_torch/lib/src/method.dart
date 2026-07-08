import 'package:np_common/size.dart';
import 'package:np_platform_raw_image/np_platform_raw_image.dart';

abstract class Method {
  Future<void> prepareResource({
    void Function(double progress, int size)? onProgress,
  });

  Future<void> cleanResource();

  Future<bool> isResourceReady();

  SizeInt getMaxSrcSize();
}

// Most common methods that take a rgb8 image and output a rgb8 image
abstract class RgbMethod extends Method {
  Future<Rgb8Image?> apply(Rgb8Image src);
}
