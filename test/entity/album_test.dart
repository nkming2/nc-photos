import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:test/test.dart';

void main() {
  group("Album", () {
    group("fromJson", () {
      test("lastUpdated", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "items": [],
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              items: [],
            ));
      });

      test("name", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "items": [],
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "album",
              items: [],
            ));
      });

      test("items", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test1.jpg",
                },
              },
            },
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test2.jpg",
                },
              },
            },
          ]
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              items: [
                AlbumFileItem(
                  file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
                  file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
                ),
              ],
            ));
      });

      test("albumFile", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "items": [],
          "albumFile": <String, dynamic>{
            "path": "/remote.php/dav/files/admin/test1.jpg",
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              items: [],
              albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ));
      });
    });

    group("toRemoteJson", () {
      test("lastUpdated", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          items: [],
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [],
        });
      });

      test("name", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          items: [],
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "items": [],
        });
      });

      test("items", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          items: [
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ),
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
            ),
          ],
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test1.jpg",
                },
              },
            },
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test2.jpg",
                },
              },
            },
          ]
        });
      });
    });

    group("toAppDbJson", () {
      test("lastUpdated", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          items: [],
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [],
        });
      });

      test("name", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          items: [],
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "items": [],
        });
      });

      test("items", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          items: [
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ),
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
            ),
          ],
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test1.jpg",
                },
              },
            },
            <String, dynamic>{
              "type": "file",
              "content": <String, dynamic>{
                "file": <String, dynamic>{
                  "path": "/remote.php/dav/files/admin/test2.jpg",
                },
              },
            },
          ]
        });
      });

      test("albumFile", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          items: [],
          albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "items": [],
          "albumFile": <String, dynamic>{
            "path": "/remote.php/dav/files/admin/test1.jpg",
          },
        });
      });
    });

    group("versioned", () {
      test("v1", () {
        final album = Album.versioned(
          version: 1,
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          items: [
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ),
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
            ),
          ],
          albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
        );
        expect(
            album,
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "album",
              items: [],
              albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ));
      });

      test("v2", () {
        final album = Album.versioned(
          version: 2,
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          items: [
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ),
            AlbumFileItem(
              file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
            ),
          ],
          albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
        );
        expect(
            album,
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "album",
              items: [
                AlbumFileItem(
                  file: File(path: "/remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
                  file: File(path: "/remote.php/dav/files/admin/test2.jpg"),
                ),
              ],
              albumFile: File(path: "/remote.php/dav/files/admin/test1.jpg"),
            ));
      });
    });
  });
}
