import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("ShareeParser", () {
    test("parse", _sharees);
  });
}

Future<void> _sharees() async {
  const json = """
{
    "ocs": {
        "meta": {
            "status": "ok",
            "statuscode": 100,
            "message": "OK",
            "totalitems": "",
            "itemsperpage": ""
        },
        "data": {
            "exact": {
                "users": [],
                "groups": [],
                "remotes": [],
                "remote_groups": [],
                "emails": [],
                "circles": [],
                "rooms": [],
                "deck": []
            },
            "users": [
                {
                    "label": "user",
                    "subline": "",
                    "icon": "icon-user",
                    "value": {
                        "shareType": 0,
                        "shareWith": "user"
                    },
                    "shareWithDisplayNameUnique": "user",
                    "status": {
                        "status": "offline",
                        "message": null,
                        "icon": null,
                        "clearAt": null
                    }
                }
            ],
            "groups": [],
            "remotes": [],
            "remote_groups": [],
            "emails": [],
            "lookup": [],
            "circles": [],
            "rooms": [],
            "deck": [],
            "lookupEnabled": true
        }
    }
}
""";
  final results = await ShareeParser().parse(json);
  expect(results, const [
    Sharee(
      type: "users",
      label: "user",
      shareType: 0,
      shareWith: "user",
      shareWithDisplayNameUnique: "user",
    ),
  ]);
}
