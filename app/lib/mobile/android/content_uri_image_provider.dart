import 'dart:ui' as ui show Codec, ImmutableBuffer;

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:nc_photos_plugin/nc_photos_plugin.dart';

class ContentUriImage extends ImageProvider<ContentUriImage>
    with EquatableMixin {
  /// Creates an object that decodes a content Uri as an image.
  const ContentUriImage(
    this.uri, {
    this.scale = 1.0,
  });

  @override
  obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<ContentUriImage>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
      ContentUriImage key, DecoderBufferCallback decode) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: key.scale,
      debugLabel: key.uri,
      informationCollector: () => <DiagnosticsNode>[
        ErrorDescription("Content uri: $uri"),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
      ContentUriImage key, DecoderBufferCallback decode) async {
    assert(key == this);
    final bytes = await ContentUri.readUri(uri);
    if (bytes.lengthInBytes == 0) {
      // The file may become available later.
      PaintingBinding.instance.imageCache.evict(key);
      throw StateError("$uri is empty and cannot be loaded as an image.");
    }
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  get props => [
        uri,
        scale,
      ];

  @override
  toString() => "${objectRuntimeType(this, "ContentUriImage")} {"
      "uri: $uri, "
      "scale: $scale, "
      "}";

  final String uri;

  /// The scale to place in the [ImageInfo] object of the image.
  final double scale;
}
