import 'package:intl/intl.dart';
import 'package:nc_photos/ci_string.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/type.dart';
import 'package:test/test.dart';

import '../test_util.dart' as util;

void main() {
  group("Album", () {
    group("fromJson", () {
      test("lastUpdated", () {
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
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(
              json,
              upgraderFactory: const _NullAlbumUpgraderFactory(),
            ),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
              sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(
              json,
              upgraderFactory: const _NullAlbumUpgraderFactory(),
            ),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "album",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
              sortProvider: const AlbumNullSortProvider(),
            ));
      });

      group("AlbumStaticProvider", () {
        test("AlbumFileItem", () {
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
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                  <String, dynamic>{
                    "type": "file",
                    "content": <String, dynamic>{
                      "file": <String, dynamic>{
                        "path": "remote.php/dav/files/admin/test2.jpg",
                      },
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          };
          expect(
              Album.fromJson(
                json,
                upgraderFactory: const _NullAlbumUpgraderFactory(),
              ),
              Album(
                lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                name: "",
                provider: AlbumStaticProvider(
                  items: [
                    AlbumFileItem(
                      addedBy: "admin".toCi(),
                      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                      file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                    ),
                    AlbumFileItem(
                      addedBy: "admin".toCi(),
                      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                      file: File(path: "remote.php/dav/files/admin/test2.jpg"),
                    ),
                  ],
                ),
                coverProvider: AlbumAutoCoverProvider(),
                sortProvider: const AlbumNullSortProvider(),
              ));
        });

        test("AlbumLabelItem", () {
          final json = <String, dynamic>{
            "version": Album.version,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
            "name": "",
            "provider": <String, dynamic>{
              "type": "static",
              "content": <String, dynamic>{
                "items": [
                  <String, dynamic>{
                    "type": "label",
                    "content": <String, dynamic>{
                      "text": "Testing",
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          };
          expect(
              Album.fromJson(
                json,
                upgraderFactory: const _NullAlbumUpgraderFactory(),
              ),
              Album(
                lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                name: "",
                provider: AlbumStaticProvider(
                  items: [
                    AlbumLabelItem(
                      addedBy: "admin".toCi(),
                      addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                      text: "Testing",
                    ),
                  ],
                ),
                coverProvider: AlbumAutoCoverProvider(),
                sortProvider: const AlbumNullSortProvider(),
              ));
        });
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        };
        expect(
            Album.fromJson(
              json,
              upgraderFactory: const _NullAlbumUpgraderFactory(),
            ),
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
              sortProvider: const AlbumNullSortProvider(),
            ));
      });

      test("AlbumTimeSortProvider", () {
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
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": true,
            },
          },
        };
        expect(
            Album.fromJson(
              json,
              upgraderFactory: const _NullAlbumUpgraderFactory(),
            ),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
              sortProvider: const AlbumTimeSortProvider(
                isAscending: true,
              ),
            ));
      });

      test("shares", _fromJsonShares);

      test("albumFile", () {
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
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.jpg",
          },
        };
        expect(
            Album.fromJson(
              json,
              upgraderFactory: const _NullAlbumUpgraderFactory(),
            ),
            Album(
              lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              name: "",
              provider: AlbumStaticProvider(
                items: [],
              ),
              coverProvider: AlbumAutoCoverProvider(),
              sortProvider: const AlbumNullSortProvider(),
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        });
      });

      group("AlbumStaticProvider", () {
        test("AlbumFileItem", () {
          final album = Album(
            lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            name: "",
            provider: AlbumStaticProvider(
              items: [
                AlbumFileItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  file: File(path: "remote.php/dav/files/admin/test2.jpg"),
                ),
              ],
            ),
            coverProvider: AlbumAutoCoverProvider(),
            sortProvider: const AlbumNullSortProvider(),
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
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                  <String, dynamic>{
                    "type": "file",
                    "content": <String, dynamic>{
                      "file": <String, dynamic>{
                        "path": "remote.php/dav/files/admin/test2.jpg",
                      },
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          });
        });

        test("AlbumLabelItem", () {
          final album = Album(
            lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            name: "",
            provider: AlbumStaticProvider(
              items: [
                AlbumLabelItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  text: "Testing",
                ),
              ],
            ),
            coverProvider: AlbumAutoCoverProvider(),
            sortProvider: const AlbumNullSortProvider(),
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
                    "type": "label",
                    "content": <String, dynamic>{
                      "text": "Testing",
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          });
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumTimeSortProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
          sortProvider: const AlbumTimeSortProvider(
            isAscending: true,
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
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": true,
            },
          },
        });
      });

      test("shares", _toRemoteJsonShares);
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        });
      });

      group("AlbumStaticProvider", () {
        test("AlbumFileItem", () {
          final album = Album(
            lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            name: "",
            provider: AlbumStaticProvider(
              items: [
                AlbumFileItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  file: File(path: "remote.php/dav/files/admin/test2.jpg"),
                ),
              ],
            ),
            coverProvider: AlbumAutoCoverProvider(),
            sortProvider: const AlbumNullSortProvider(),
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
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                  <String, dynamic>{
                    "type": "file",
                    "content": <String, dynamic>{
                      "file": <String, dynamic>{
                        "path": "remote.php/dav/files/admin/test2.jpg",
                      },
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          });
        });

        test("AlbumLabelItem", () {
          final album = Album(
            lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
            name: "",
            provider: AlbumStaticProvider(
              items: [
                AlbumLabelItem(
                  addedBy: "admin".toCi(),
                  addedAt: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                  text: "Testing",
                ),
              ],
            ),
            coverProvider: AlbumAutoCoverProvider(),
            sortProvider: const AlbumNullSortProvider(),
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
                    "type": "label",
                    "content": <String, dynamic>{
                      "text": "Testing",
                    },
                    "addedBy": "admin",
                    "addedAt": "2020-01-02T03:04:05.678901Z",
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{},
            },
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          });
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
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
            "content": <String, dynamic>{},
          },
        });
      });

      test("AlbumTimeSortProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
          sortProvider: const AlbumTimeSortProvider(
            isAscending: true,
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
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": true,
            },
          },
        });
      });

      test("shares", _toAppDbJsonShares);

      test("albumFile", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: AlbumAutoCoverProvider(),
          sortProvider: const AlbumNullSortProvider(),
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
          "sortProvider": <String, dynamic>{
            "type": "null",
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

    test("AlbumUpgraderV3", () {
      final json = <String, dynamic>{
        "version": 3,
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
      };
      expect(AlbumUpgraderV3()(json), <String, dynamic>{
        "version": 3,
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
        "sortProvider": <String, dynamic>{
          "type": "time",
          "content": <String, dynamic>{
            "isAscending": false,
          },
        },
        "albumFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.json",
        },
      });
    });

    group("AlbumUpgraderV4", () {
      test("Non AlbumFileItem", () {
        final json = <String, dynamic>{
          "version": 4,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [
                <String, dynamic>{
                  "type": "label",
                  "content": <String, dynamic>{
                    "text": "123",
                  },
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
          },
        };
        expect(AlbumUpgraderV4()(json), <String, dynamic>{
          "version": 4,
          "lastUpdated": "2020-01-02T03:04:05.678901Z",
          "provider": <String, dynamic>{
            "type": "static",
            "content": <String, dynamic>{
              "items": [
                <String, dynamic>{
                  "type": "label",
                  "content": <String, dynamic>{
                    "text": "123",
                  },
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
          },
        });
      });

      group("AlbumFileItem", () {
        test("drop metadata", () {
          final json = <String, dynamic>{
            "version": 4,
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
                        "metadata": <String, dynamic>{
                          "Make": "Super",
                          "Model": "A123",
                        },
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
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          };
          expect(AlbumUpgraderV4()(json), <String, dynamic>{
            "version": 4,
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
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          });
        });

        test("lastModified as latestItemTime", () {
          final json = <String, dynamic>{
            "version": 4,
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
                        "lastModified": "2020-01-02T03:04:05.678901Z",
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
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          };
          expect(AlbumUpgraderV4()(json), <String, dynamic>{
            "version": 4,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
            "provider": <String, dynamic>{
              "type": "static",
              "content": <String, dynamic>{
                "latestItemTime": "2020-01-02T03:04:05.678901Z",
                "items": [
                  <String, dynamic>{
                    "type": "file",
                    "content": <String, dynamic>{
                      "file": <String, dynamic>{
                        "path": "remote.php/dav/files/admin/test1.jpg",
                        "lastModified": "2020-01-02T03:04:05.678901Z",
                      },
                    },
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{
                "coverFile": <String, dynamic>{
                  "path": "remote.php/dav/files/admin/test1.jpg",
                  "lastModified": "2020-01-02T03:04:05.678901Z",
                },
              },
            },
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          });
        });

        test("dateTimeOriginal as latestItemTime", () {
          final json = <String, dynamic>{
            "version": 4,
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
                        "metadata": <String, dynamic>{
                          "exif": <String, dynamic>{
                            // convert 2020-01-02T03:04:05Z to local time
                            "DateTimeOriginal":
                                DateFormat("yyyy:MM:dd HH:mm:ss").format(
                                    DateTime.utc(2020, 1, 2, 3, 4, 5)
                                        .toLocal()),
                          },
                        },
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
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          };
          expect(AlbumUpgraderV4()(json), <String, dynamic>{
            "version": 4,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
            "provider": <String, dynamic>{
              "type": "static",
              "content": <String, dynamic>{
                "latestItemTime": "2020-01-02T03:04:05.000Z",
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
              "content": <String, dynamic>{
                "coverFile": <String, dynamic>{
                  "path": "remote.php/dav/files/admin/test1.jpg",
                },
              },
            },
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          });
        });

        test("overrideDateTime as latestItemTime", () {
          final json = <String, dynamic>{
            "version": 4,
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
                        "overrideDateTime": "2020-01-02T03:04:05.678901Z",
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
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          };
          expect(AlbumUpgraderV4()(json), <String, dynamic>{
            "version": 4,
            "lastUpdated": "2020-01-02T03:04:05.678901Z",
            "provider": <String, dynamic>{
              "type": "static",
              "content": <String, dynamic>{
                "latestItemTime": "2020-01-02T03:04:05.678901Z",
                "items": [
                  <String, dynamic>{
                    "type": "file",
                    "content": <String, dynamic>{
                      "file": <String, dynamic>{
                        "path": "remote.php/dav/files/admin/test1.jpg",
                        "overrideDateTime": "2020-01-02T03:04:05.678901Z",
                      },
                    },
                  },
                ],
              },
            },
            "coverProvider": <String, dynamic>{
              "type": "auto",
              "content": <String, dynamic>{
                "coverFile": <String, dynamic>{
                  "path": "remote.php/dav/files/admin/test1.jpg",
                  "overrideDateTime": "2020-01-02T03:04:05.678901Z",
                },
              },
            },
            "sortProvider": <String, dynamic>{
              "type": "time",
              "content": <String, dynamic>{
                "isAscending": false,
              },
            },
            "albumFile": <String, dynamic>{
              "path": "remote.php/dav/files/admin/test1.json",
            },
          });
        });
      });
    });

    group("AlbumUpgraderV5", () {
      final account = util.buildAccount(username: "user1");

      test("w/ ownerId", () {
        final json = <String, dynamic>{
          "version": 5,
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
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
            "ownerId": "admin",
          },
        };
        expect(AlbumUpgraderV5(account)(json), <String, dynamic>{
          "version": 5,
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
                  "addedBy": "admin",
                  "addedAt": "2020-01-02T03:04:05.678901Z",
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
            "ownerId": "admin",
          },
        });
      });

      test("w/o ownerId", () {
        final json = <String, dynamic>{
          "version": 5,
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
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
          },
        };
        expect(AlbumUpgraderV5(account)(json), <String, dynamic>{
          "version": 5,
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
                  "addedBy": "user1",
                  "addedAt": "2020-01-02T03:04:05.678901Z",
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
          "albumFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.json",
          },
        });
      });

      test("w/o albumFile", () {
        final json = <String, dynamic>{
          "version": 5,
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
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
        };
        expect(AlbumUpgraderV5(account)(json), <String, dynamic>{
          "version": 5,
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
                  "addedBy": "user1",
                  "addedAt": "2020-01-02T03:04:05.678901Z",
                },
              ],
            },
          },
          "coverProvider": <String, dynamic>{
            "type": "auto",
            "content": <String, dynamic>{},
          },
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
        });
      });

      test("w/ external albumFile", () {
        final json = <String, dynamic>{
          "version": 5,
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
          "sortProvider": <String, dynamic>{
            "type": "time",
            "content": <String, dynamic>{
              "isAscending": false,
            },
          },
        };
        final albumFile = File(
          path: "remote.php/dav/files/admin/test1.json",
          ownerId: "admin".toCi(),
        );
        expect(
            AlbumUpgraderV5(account, albumFile: albumFile)(json),
            <String, dynamic>{
              "version": 5,
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
                      "addedBy": "admin",
                      "addedAt": "2020-01-02T03:04:05.678901Z",
                    },
                  ],
                },
              },
              "coverProvider": <String, dynamic>{
                "type": "auto",
                "content": <String, dynamic>{},
              },
              "sortProvider": <String, dynamic>{
                "type": "time",
                "content": <String, dynamic>{
                  "isAscending": false,
                },
              },
            });
      });
    });
  });
}

void _fromJsonShares() {
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
      "content": <String, dynamic>{},
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "shares": <JsonObj>[
      {
        "userId": "admin",
        "displayName": "admin",
        "sharedAt": "2020-01-02T03:04:05.000Z",
      },
    ],
  };
  expect(
      Album.fromJson(
        json,
        upgraderFactory: const _NullAlbumUpgraderFactory(),
      ),
      Album(
        lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
        name: "",
        provider: AlbumStaticProvider(
          items: [],
        ),
        coverProvider: AlbumAutoCoverProvider(),
        sortProvider: const AlbumNullSortProvider(),
        shares: [util.buildAlbumShare(userId: "admin")],
      ));
}

void _toRemoteJsonShares() {
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
    name: "",
    provider: AlbumStaticProvider(
      items: [],
    ),
    coverProvider: AlbumAutoCoverProvider(),
    sortProvider: const AlbumNullSortProvider(),
    shares: [util.buildAlbumShare(userId: "admin")],
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
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "shares": [
      <String, dynamic>{
        "userId": "admin",
        "displayName": "admin",
        "sharedAt": "2020-01-02T03:04:05.000Z",
      },
    ],
  });
}

void _toAppDbJsonShares() {
  final album = Album(
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
    name: "",
    provider: AlbumStaticProvider(
      items: [],
    ),
    coverProvider: AlbumAutoCoverProvider(),
    sortProvider: const AlbumNullSortProvider(),
    shares: [util.buildAlbumShare(userId: "admin")],
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
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "shares": [
      <String, dynamic>{
        "userId": "admin",
        "displayName": "admin",
        "sharedAt": "2020-01-02T03:04:05.000Z",
      },
    ],
  });
}

class _NullAlbumUpgraderFactory extends AlbumUpgraderFactory {
  const _NullAlbumUpgraderFactory();

  @override
  buildV1() => null;
  @override
  buildV2() => null;
  @override
  buildV3() => null;
  @override
  buildV4() => null;
  @override
  buildV5() => null;
  @override
  buildV6() => null;
}
