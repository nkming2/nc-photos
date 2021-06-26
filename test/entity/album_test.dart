import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:test/test.dart';

void main() {
  group("Album", () {
    group("fromJson", () {
      test("lastUpdated", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
            ));
      });

      test("name", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "album",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
            ));
      });

      test("AlbumStaticProvider", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test1.jpg",
                    },
                  },
                },
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test2.jpg",
                    },
                  },
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [
                  AlbumFileItem(
                    file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                  ),
                  AlbumFileItem(
                    file: File(path: "remote.php/dav/files/admin/test2.jpg"),
                  ),
                ],
              ),
              coverProvider: AlbumAutoCoverProvider(),
            ));
      });

      test("AlbumAutoCoverProvider", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{
              "coverFile": <String, dynamic>{
                "path": "remote.php/dav/files/admin/test1.jpg",
              },
            },
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(
                coverFile: File(
                  path: "remote.php/dav/files/admin/test1.jpg",
                ),
              ),
            ));
      });

      test("albumFile", () {
        final json = <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.jpg",
          },
        };
        expect(
            Album.fromJson(json),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
              albumFile: File(path: "remote.php/dav/files/admin/test1.jpg"),
            ));
      });
    });

    group("toRemoteJson", () {
      test("lastUpdated", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("name", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumStaticProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [
              AlbumFileItem(
                file: File(path: "remote.php/dav/files/admin/test1.jpg"),
              ),
              AlbumFileItem(
                file: File(path: "remote.php/dav/files/admin/test2.jpg"),
              ),
            ],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test1.jpg",
                    },
                  },
                },
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test2.jpg",
                    },
                  },
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumAutoCoverProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(
              coverFile: File(path: "remote.php/dav/files/admin/test1.jpg")),
        );
        expect(album.toRemoteJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{
              "coverFile": <String, dynamic>{
                "path": "remote.php/dav/files/admin/test1.jpg",
              },
            },
          },
        });
      });
    });

    group("toAppDbJson", () {
      test("lastUpdated", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("name", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "album",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "album",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumStaticProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [
              AlbumFileItem(
                file: File(path: "remote.php/dav/files/admin/test1.jpg"),
              ),
              AlbumFileItem(
                file: File(path: "remote.php/dav/files/admin/test2.jpg"),
              ),
            ],
          ),
          coverProvider: AlbumAutoCoverProvider(),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test1.jpg",
                    },
                  },
                },
                <String, dynamic>{
                  "type": "file",
                  "content": <String, dynamic>{
                    "file": <String, dynamic>{
                      "path": "remote.php/dav/files/admin/test2.jpg",
                    },
                  },
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumAutoCoverProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(
            coverFile: File(
              path: "remote.php/dav/files/admin/test1.jpg",
            ),
          ),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{
              "coverFile": <String, dynamic>{
                "path": "remote.php/dav/files/admin/test1.jpg",
              },
            },
          },
        });
      });

      test("albumFile", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
          albumFile: File(path: "remote.php/dav/files/admin/test1.jpg"),
        );
        expect(album.toAppDbJson(), <String, dynamic>{
          "version": Album.version,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "name": "",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.jpg",
          },
        });
      });
    });

    test("AlbumUpgraderV1", () {
      final json = <String, dynamic>{
        "version": 1,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
        "items": [
          <String, dynamic>{
            "type": "file",
            "content": <String, dynamic>{
              "file": <String, dynamic>{
                "path": "remote.php/dav/files/admin/test1.jpg",
              },
            },
          },
        ],
        "albumFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.json",
        },
      };
      expect(AlbumUpgraderV1()(json), <String, dynamic>{
        "version": 1,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
        "items": [],
        "albumFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.json",
        },
      });
    });

    test("AlbumUpgraderV2", () {
      final json = <String, dynamic>{
        "version": 2,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
        "items": [
          <String, dynamic>{
            "type": "file",
            "content": <String, dynamic>{
              "file": <String, dynamic>{
                "path": "remote.php/dav/files/admin/test1.jpg",
              },
            },
          },
        ],
        "albumFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.json",
        },
      };
      expect(AlbumUpgraderV2()(json), <String, dynamic>{
        "version": 2,
        "lastUpdated": "2020-01-02T03:04:05.678901Z",
        "provider": <String, dynamic>{
          "type": "static",
          "content": <String, dynamic>{
            "items": [
              <String, dynamic>{
                "type": "file",
                "content": <String, dynamic>{
                  "file": <String, dynamic>{
                    "path": "remote.php/dav/files/admin/test1.jpg",
                  },
                },
              },
            ],
          },
        },
        "coverProvider": <String, dynamic>{
          "type": "auto",
          "content": <String, dynamic>{},
        },
        "albumFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.json",
        },
      });
    });
  });
}
