import 'package:np_common/object_util.dart';
import 'package:test/test.dart';

void main() {
  group("ObjectExtension", () {
    test("also", () {
      const obj = Object();
      expect(obj.also((obj) => 1), obj);
    });

    test("alsoFuture", () async {
      const obj = Object();
      expect(await obj.alsoFuture((obj) async => 1), obj);
    });

    test("let", () {
      const obj = Object();
      expect(obj.let((obj) => 1), 1);
    });

    test("letFuture", () async {
      const obj = Object();
      expect(await obj.letFuture((obj) => Future.value(1)), 1);
    });
  });
}
