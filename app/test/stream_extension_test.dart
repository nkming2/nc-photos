import 'package:nc_photos/stream_extension.dart';
import 'package:test/test.dart';

void main() {
  group("StreamExtension", () {
    group("per", () {
      test("count = 1", _perCount1);
      test("count = 2", _perCount2);
    });
  });
}

Future<void> _perCount1() async {
  final stream = () async* {
    for (var i = 0; i < 10; ++i) {
      yield i;
    }
  }();
  expect(await stream.per(1).toList(), [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
}

Future<void> _perCount2() async {
  final stream = () async* {
    for (var i = 0; i < 10; ++i) {
      yield i;
    }
  }();
  expect(await stream.per(2).toList(), [0, 2, 4, 6, 8]);
}
