import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("ShareParser", () {
    test("parse", _shares);
  });
}

Future<void> _shares() async {
  const xml = """
{
    "ocs": {
        "meta": {
            "status": "ok",
            "statuscode": 200,
            "message": "OK"
        },
        "data": [
            {
                "id": "123",
                "share_type": 0,
                "uid_owner": "admin",
                "displayname_owner": "super",
                "permissions": 19,
                "can_edit": true,
                "can_delete": true,
                "stime": 1672531200,
                "parent": null,
                "expiration": null,
                "token": null,
                "uid_file_owner": "admin",
                "note": "",
                "label": null,
                "displayname_file_owner": "awesome-admin",
                "path": "/Nextcloud.png",
                "item_type": "file",
                "mimetype": "image/png",
                "has_preview": true,
                "storage_id": "home::admin",
                "storage": 1,
                "item_source": 123456,
                "file_source": 123456,
                "file_parent": 1,
                "file_target": "/Nextcloud.png",
                "share_with": "user",
                "share_with_displayname": "awesome",
                "share_with_displayname_unique": "awesome",
                "status": {
                    "status": "offline",
                    "message": null,
                    "icon": null,
                    "clearAt": null
                },
                "mail_send": 0,
                "hide_download": 0,
                "url": "http://192.168.0.1/s/NCNxZJkkqdGPF4J"
            }
        ]
    }
}
""";
  final results = await ShareParser().parse(xml);
  expect(results, const [
    Share(
      id: "123",
      shareType: 0,
      stime: 1672531200,
      uidOwner: "admin",
      displaynameOwner: "super",
      uidFileOwner: "admin",
      path: "/Nextcloud.png",
      itemType: "file",
      mimeType: "image/png",
      itemSource: 123456,
      shareWith: "user",
      shareWithDisplayName: "awesome",
      url: "http://192.168.0.1/s/NCNxZJkkqdGPF4J",
    ),
  ]);
}
