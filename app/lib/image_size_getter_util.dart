import 'dart:io';
import 'dart:typed_data';

import 'package:image_size_getter/image_size_getter.dart';

class AsyncMemoryInput extends AsyncImageInput {
  final Uint8List bytes;
  const AsyncMemoryInput(this.bytes);

  factory AsyncMemoryInput.byteBuffer(ByteBuffer buffer) =>
      AsyncMemoryInput(buffer.asUint8List());

  @override
  getRange(int start, int end) async => bytes.sublist(start, end);

  @override
  get length async => bytes.length;

  @override
  exists() async => bytes.isNotEmpty;
}

class AsyncFileInput extends AsyncImageInput {
  final File file;

  AsyncFileInput(this.file);

  @override
  getRange(int start, int end) => file
      .openRead(start, end)
      .reduce((previous, element) => previous + element);

  @override
  get length => file.length();

  @override
  exists() => file.exists();
}
