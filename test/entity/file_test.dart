import 'package:nc_photos/entity/exif.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/or_null.dart';
import 'package:test/test.dart';

void main() {
  group("compareFileDateTimeDescending", () {
    test("lastModified a>b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        lastModified: DateTime.utc(2021),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        lastModified: DateTime.utc(2020),
      );
      expect(compareFileDateTimeDescending(a, b), lessThan(0));
    });

    test("lastModified a<b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        lastModified: DateTime.utc(2020),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        lastModified: DateTime.utc(2021),
      );
      expect(compareFileDateTimeDescending(a, b), greaterThan(0));
    });

    test("lastModified a==b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        lastModified: DateTime.utc(2021),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        lastModified: DateTime.utc(2021),
      );
      expect(compareFileDateTimeDescending(a, b), lessThan(0));
    });

    test("exif a>b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2021:01:02 03:04:05",
          }),
        ),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2020:01:02 03:04:05",
          }),
        ),
      );
      expect(compareFileDateTimeDescending(a, b), lessThan(0));
    });

    test("exif a<b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2020:01:02 03:04:05",
          }),
        ),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2021:01:02 03:04:05",
          }),
        ),
      );
      expect(compareFileDateTimeDescending(a, b), greaterThan(0));
    });

    test("exif a==b", () {
      final a = File(
        path: "remote.php/dav/files/admin/test1.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2021:01:02 03:04:05",
          }),
        ),
      );
      final b = File(
        path: "remote.php/dav/files/admin/test2.jpg",
        metadata: Metadata(
          exif: Exif({
            "DateTimeOriginal": "2021:01:02 03:04:05",
          }),
        ),
      );
      expect(compareFileDateTimeDescending(a, b), lessThan(0));
    });
  });

  group("Metadata", () {
    group("fromJson", () {
      test("lastUpdated", () {
        final json = <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
        };
        expect(Metadata.fromJson(json),
            Metadata(lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901)));
      });

      test("fileEtag", () {
        final json = <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "fileEtag": "8a3e0799b6f0711c23cc2d93950eceb5",
        };
        expect(
            Metadata.fromJson(json),
            Metadata(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
            ));
      });

      test("imageWidth", () {
        final json = <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "imageWidth": 1024,
        };
        expect(
            Metadata.fromJson(json),
            Metadata(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              imageWidth: 1024,
            ));
      });

      test("imageHeight", () {
        final json = <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "imageHeight": 768,
        };
        expect(
            Metadata.fromJson(json),
            Metadata(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              imageHeight: 768,
            ));
      });

      test("exif", () {
        final json = <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "exif": <String, dynamic>{
            "Make": "dummy",
          },
        };
        expect(
            Metadata.fromJson(json),
            Metadata(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              exif: Exif({
                "Make": "dummy",
              }),
            ));
      });
    });

    group("toJson", () {
      test("lastUpdated", () {
        final metadata =
            Metadata(lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901));
        expect(metadata.toJson(), <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
        });
      });

      test("fileEtag", () {
        final metadata = Metadata(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
        );
        expect(metadata.toJson(), <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "fileEtag": "8a3e0799b6f0711c23cc2d93950eceb5",
        });
      });

      test("imageWidth", () {
        final metadata = Metadata(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          imageWidth: 1024,
        );
        expect(metadata.toJson(), <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "imageWidth": 1024,
        });
      });

      test("imageHeight", () {
        final metadata = Metadata(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          imageHeight: 768,
        );
        expect(metadata.toJson(), <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "imageHeight": 768,
        });
      });

      test("exif", () {
        final metadata = Metadata(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          exif: Exif({
            "Make": "dummy",
          }),
        );
        expect(metadata.toJson(), <String, dynamic>{
          "version": Metadata.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "exif": <String, dynamic>{
            "Make": "dummy",
          },
        });
      });
    });
  });

  group("MetadataUpgraderV1", () {
    test("call webp", () {
      final json = <String, dynamic>{
        "version": 1,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
      };
      expect(MetadataUpgraderV1(fileContentType: "image/webp")(json), null);
    });

    test("call jpeg", () {
      final json = <String, dynamic>{
        "version": 1,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
      };
      expect(
          MetadataUpgraderV1(fileContentType: "image/jpeg")(json),
          <String, dynamic>{
            "version": 1,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
          });
    });
  });

  group("MetadataUpgraderV2", () {
    test("call rotated jpeg", () {
      final json = <String, dynamic>{
        "version": 2,
        "exif": <String, dynamic>{
          "Orientation": 5,
        },
        "imageWidth": 1024,
        "imageHeight": 768,
      };
      expect(
          MetadataUpgraderV2(fileContentType: "image/jpeg")(json),
          <String, dynamic>{
            "version": 2,
            "exif": <String, dynamic>{
              "Orientation": 5,
            },
            "imageWidth": 768,
            "imageHeight": 1024,
          });
    });

    test("call non-rotated jpeg", () {
      final json = <String, dynamic>{
        "version": 2,
        "exif": <String, dynamic>{
          "Orientation": 1,
        },
        "imageWidth": 1024,
        "imageHeight": 768,
      };
      expect(
          MetadataUpgraderV2(fileContentType: "image/jpeg")(json),
          <String, dynamic>{
            "version": 2,
            "exif": <String, dynamic>{
              "Orientation": 1,
            },
            "imageWidth": 1024,
            "imageHeight": 768,
          });
    });

    test("call webp", () {
      final json = <String, dynamic>{
        "version": 2,
        "exif": <String, dynamic>{
          "Orientation": 5,
        },
        "imageWidth": 1024,
        "imageHeight": 768,
      };
      expect(
          MetadataUpgraderV2(fileContentType: "image/webp")(json),
          <String, dynamic>{
            "version": 2,
            "exif": <String, dynamic>{
              "Orientation": 5,
            },
            "imageWidth": 1024,
            "imageHeight": 768,
          });
    });
  });

  group("File", () {
    group("constructor", () {
      test("path trim slash", () {
        final file = File(path: "/remote.php/dav/");
        expect(file.path, "remote.php/dav");
      });

      test("path slash only", () {
        final file = File(path: "/");
        expect(file.path, "");
      });
    });

    group("fromJson", () {
      test("path", () {
        final json = <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
        };
        final file = File.fromJson(json);
        expect(file, File(path: "remote.php/dav/files/admin/test.jpg"));
      });

      test("contentLength", () {
        final json = <String, dynamic>{
          "path": "",
          "contentLength": 123,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", contentLength: 123));
      });

      test("contentType", () {
        final json = <String, dynamic>{
          "path": "",
          "contentType": "image/jpeg",
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", contentType: "image/jpeg"));
      });

      test("etag", () {
        final json = <String, dynamic>{
          "path": "",
          "etag": "8a3e0799b6f0711c23cc2d93950eceb5",
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", etag: "8a3e0799b6f0711c23cc2d93950eceb5"));
      });

      test("lastModified", () {
        final json = <String, dynamic>{
          "path": "",
          "lastModified": "2020-01-02T03:04:05.678901Z",
        };
        final file = File.fromJson(json);
        expect(
            file,
            File(
              path: "",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            ));
      });

      test("isCollection", () {
        final json = <String, dynamic>{
          "path": "",
          "isCollection": true,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", isCollection: true));
      });

      test("usedBytes", () {
        final json = <String, dynamic>{
          "path": "",
          "usedBytes": 123456,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", usedBytes: 123456));
      });

      test("hasPreview", () {
        final json = <String, dynamic>{
          "path": "",
          "hasPreview": true,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", hasPreview: true));
      });

      test("fileId", () {
        final json = <String, dynamic>{
          "path": "",
          "fileId": 123,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", fileId: 123));
      });

      test("ownerId", () {
        final json = <String, dynamic>{
          "path": "",
          "ownerId": "admin",
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", ownerId: "admin"));
      });

      test("metadata", () {
        final json = <String, dynamic>{
          "path": "",
          "metadata": <String, dynamic>{
            "version": Metadata.version,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
          },
        };
        final file = File.fromJson(json);
        expect(
            file,
            File(
              path: "",
              metadata: Metadata(
                lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              ),
            ));
      });

      test("isArchived", () {
        final json = <String, dynamic>{
          "path": "",
          "isArchived": true,
        };
        final file = File.fromJson(json);
        expect(file, File(path: "", isArchived: true));
      });
    });

    group("toJson", () {
      test("path", () {
        final file = File(path: "remote.php/dav/files/admin/test.jpg");
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
        });
      });

      test("contentLength", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg", contentLength: 123);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "contentLength": 123,
        });
      });

      test("contentType", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg",
            contentType: "image/jpeg");
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "contentType": "image/jpeg",
        });
      });

      test("etag", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg",
            etag: "8a3e0799b6f0711c23cc2d93950eceb5");
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "etag": "8a3e0799b6f0711c23cc2d93950eceb5",
        });
      });

      test("lastModified", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg",
            lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901));
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "lastModified": "2020-01-02T03:04:05.678901Z",
        });
      });

      test("isCollection", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg", isCollection: true);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "isCollection": true,
        });
      });

      test("usedBytes", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg", usedBytes: 123456);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "usedBytes": 123456,
        });
      });

      test("hasPreview", () {
        final file =
            File(path: "remote.php/dav/files/admin/test.jpg", hasPreview: true);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "hasPreview": true,
        });
      });

      test("fileId", () {
        final file =
            File(path: "remote.php/dav/files/admin/test.jpg", fileId: 123);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "fileId": 123,
        });
      });

      test("ownerId", () {
        final file =
            File(path: "remote.php/dav/files/admin/test.jpg", ownerId: "admin");
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "ownerId": "admin",
        });
      });

      test("metadata", () {
        final file = File(
            path: "remote.php/dav/files/admin/test.jpg",
            metadata: Metadata(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            ));
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "metadata": <String, dynamic>{
            "version": Metadata.version,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
          },
        });
      });

      test("isArchived", () {
        final file =
            File(path: "remote.php/dav/files/admin/test.jpg", isArchived: true);
        expect(file.toJson(), <String, dynamic>{
          "path": "remote.php/dav/files/admin/test.jpg",
          "isArchived": true,
        });
      });
    });

    group("copyWith", () {
      final src = File(
        path: "remote.php/dav/files/admin/test.jpg",
        contentLength: 123,
        contentType: "image/jpeg",
        etag: "8a3e0799b6f0711c23cc2d93950eceb5",
        lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
        isCollection: true,
        usedBytes: 123456,
        hasPreview: true,
        fileId: 123,
        ownerId: "admin",
        metadata: null,
        isArchived: true,
      );

      test("path", () {
        final file = src.copyWith(path: "remote.php/dav/files/admin/test.png");
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.png",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("contentLength", () {
        final file = src.copyWith(contentLength: 321);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 321,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("contentType", () {
        final file = src.copyWith(contentType: "image/png");
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/png",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("etag", () {
        final file = src.copyWith(etag: "000");
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "000",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("lastModified", () {
        final now = DateTime.now();
        final file = src.copyWith(lastModified: now);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: now,
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("isCollection", () {
        final file = src.copyWith(isCollection: false);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: false,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("usedBytes", () {
        final file = src.copyWith(usedBytes: 999999);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 999999,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("hasPreview", () {
        final file = src.copyWith(hasPreview: false);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: false,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("fileId", () {
        final file = src.copyWith(fileId: 321);
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 321,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("ownerId", () {
        final file = src.copyWith(ownerId: "user");
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "user",
              isArchived: true,
            ));
      });

      test("metadata", () {
        final metadata = Metadata();
        final file = src.copyWith(metadata: OrNull(metadata));
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              metadata: metadata,
              isArchived: true,
            ));
      });

      test("clear metadata", () {
        final src = File(
          path: "remote.php/dav/files/admin/test.jpg",
          contentLength: 123,
          contentType: "image/jpeg",
          etag: "8a3e0799b6f0711c23cc2d93950eceb5",
          lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          isCollection: true,
          usedBytes: 123456,
          hasPreview: true,
          fileId: 123,
          ownerId: "admin",
          metadata: Metadata(),
          isArchived: true,
        );
        final file = src.copyWith(metadata: OrNull(null));
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: true,
            ));
      });

      test("isArchived", () {
        final file = src.copyWith(isArchived: OrNull(false));
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
              isArchived: false,
            ));
      });

      test("clear isArchived", () {
        final file = src.copyWith(isArchived: OrNull(null));
        expect(
            file,
            File(
              path: "remote.php/dav/files/admin/test.jpg",
              contentLength: 123,
              contentType: "image/jpeg",
              etag: "8a3e0799b6f0711c23cc2d93950eceb5",
              lastModified: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              isCollection: true,
              usedBytes: 123456,
              hasPreview: true,
              fileId: 123,
              ownerId: "admin",
            ));
      });
    });

    group("strippedPath", () {
      test("file", () {
        final file = File(path: "remote.php/dav/files/admin/test.jpg");
        expect(file.strippedPath, "test.jpg");
      });

      test("root dir", () {
        final file = File(path: "remote.php/dav/files/admin");
        expect(file.strippedPath, ".");
      });
    });
  });
}
