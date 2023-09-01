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

class ImageProcessorUploadSuccessEvent implements ImageProcessorEvent {
  const ImageProcessorUploadSuccessEvent._();

  factory ImageProcessorUploadSuccessEvent.fromNativeEvent(dynamic ev) {
    assert(ev.event == _id);
    return const ImageProcessorUploadSuccessEvent._();
  }

  static const _id = "ImageProcessorUploadSuccessEvent";
}
