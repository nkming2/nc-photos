import 'package:np_api/np_api.dart';
import 'package:test/test.dart';

void main() {
  group("TagParser", () {
    test("parse", _tags);
  });
}

Future<void> _tags() async {
  const xml = """
<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:" xmlns:s="http://sabredav.org/ns" xmlns:oc="http://owncloud.org/ns" xmlns:nc="http://nextcloud.org/ns">
  <d:response>
    <d:href>/remote.php/dav/systemtags/</d:href>
    <d:propstat>
      <d:prop>
        <oc:id/>
        <oc:display-name/>
        <oc:user-visible/>
        <oc:user-assignable/>
        <oc:can-assign/>
      </d:prop>
      <d:status>HTTP/1.1 404 Not Found</d:status>
    </d:propstat>
  </d:response>
  <d:response>
    <d:href>/remote.php/dav/systemtags/1</d:href>
    <d:propstat>
      <d:prop>
        <oc:id>1</oc:id>
        <oc:display-name>super-tag</oc:display-name>
        <oc:user-visible>true</oc:user-visible>
        <oc:user-assignable>true</oc:user-assignable>
        <oc:can-assign>true</oc:can-assign>
      </d:prop>
      <d:status>HTTP/1.1 200 OK</d:status>
    </d:propstat>
  </d:response>
</d:multistatus>
""";
  final results = await TagParser().parse(xml);
  expect(results, const [
    Tag(
      href: "/remote.php/dav/systemtags/1",
      id: 1,
      displayName: "super-tag",
      userVisible: true,
      userAssignable: true,
    ),
  ]);
}
