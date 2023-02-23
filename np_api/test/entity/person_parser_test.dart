import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("PersonParser", () {
    test("parse", _persons);
  });
}

Future<void> _persons() async {
  const json = """
{
    "ocs": {
        "meta": {
            "status": "ok",
            "statuscode": 200,
            "message": "OK"
        },
        "data": [
            {
                "name": "Random Person",
                "thumbFaceId": 1,
                "count": 3
            },
            {
                "name": "Random Cat",
                "thumbFaceId": 10,
                "count": 4
            }
        ]
    }
}
""";
  final results = await PersonParser().parse(json);
  expect(results, const [
    Person(
      name: "Random Person",
      thumbFaceId: 1,
      count: 3,
    ),
    Person(
      name: "Random Cat",
      thumbFaceId: 10,
      count: 4,
    ),
  ]);
}
