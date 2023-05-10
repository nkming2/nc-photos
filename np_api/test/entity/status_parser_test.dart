import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("StatusParser", () {
    group("parse", () {
      test("Nextcloud 25", _nextcloud25);
    });
  });
}

Future<void> _nextcloud25() async {
  const json = """
{
    "installed": true,
    "maintenance": false,
    "needsDbUpgrade": false,
    "version": "25.0.2.3",
    "versionstring": "25.0.2",
    "edition": "",
    "productname": "Nextcloud",
    "extendedSupport": false
}
""";
  final results = await StatusParser().parse(json);
  expect(
    results,
    const Status(
      version: "25.0.2.3",
      versionString: "25.0.2",
      productName: "Nextcloud",
    ),
  );
}
