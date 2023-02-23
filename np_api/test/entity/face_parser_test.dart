import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("FaceParser", () {
    test("parse", _faces);
  });
}

Future<void> _faces() async {
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
                "id": 1,
                "fileId": 111
            },
            {
                "id": 2,
                "fileId": 222
            },
            {
                "id": 10,
                "fileId": 333
            }
        ]
    }
}
""";
  final results = await FaceParser().parse(json);
  expect(results, const [
    Face(
      id: 1,
      fileId: 111,
    ),
    Face(
      id: 2,
      fileId: 222,
    ),
    Face(
      id: 10,
      fileId: 333,
    ),
  ]);
}
