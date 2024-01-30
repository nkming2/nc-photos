import 'package:to_string/to_string.dart';

part 'event.g.dart';

abstract class ImageProcessorEvent {
  static ImageProcessorEvent fromNativeEvent(dynamic ev) {
    final id = ev["event"];
    switch (id) {
      case ImageProcessorUploadSuccessEvent._id:
        return ImageProcessorUploadSuccessEvent.fromNativeEvent(ev);
      default:
        throw UnsupportedError("Unknown event: $id");
    }
  }
}

@toString
class ImageProcessorUploadSuccessEvent implements ImageProcessorEvent {
  const ImageProcessorUploadSuccessEvent._();

  factory ImageProcessorUploadSuccessEvent.fromNativeEvent(dynamic ev) {
    assert(ev.event == _id);
    return const ImageProcessorUploadSuccessEvent._();
  }

  @override
  String toString() => _$toString();

  static const _id = "ImageProcessorUploadSuccessEvent";
}
