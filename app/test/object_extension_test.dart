import 'package:nc_photos/object_extension.dart';
import 'package:test/test.dart';

void main() {
  group("ObjectExtension", () {
    test("apply", () {
      const obj = Object();
      expect(obj.apply((obj) => 1), obj);
    });

    test("applyFuture", () async {
      const obj = Object();
      expect(await obj.applyFuture((obj) async => 1), obj);
    });

    test("run", () {
      const obj = Object();
      expect(obj.run((obj) => 1), 1);
    });

    test("runFuture", () async {
      const obj = Object();
      expect(await obj.runFuture((obj) => Future.value(1)), 1);
    });
  });
}
