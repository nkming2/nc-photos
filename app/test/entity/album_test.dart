import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:intl/intl.dart';
import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
import 'package:nc_photos/entity/album/upgrader.dart';
import 'package:nc_photos/entity/file.dart';
import 'package:nc_photos/entity/file_descriptor.dart';
import 'package:nc_photos/entity/sqlite/database.dart' as sql;
import 'package:np_common/ci_string.dart';
import 'package:np_common/type.dart';
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
              coverProvider: const AlbumAutoCoverProvider(),
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
              coverProvider: const AlbumAutoCoverProvider(),
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
                coverProvider: const AlbumAutoCoverProvider(),
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
                coverProvider: const AlbumAutoCoverProvider(),
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
                "fdPath": "remote.php/dav/files/admin/test1.jpg",
                "fdId": 1,
                "fdMime": null,
                "fdIsArchived": false,
                "fdIsFavorite": false,
                "fdDateTime": "2020-01-02T03:04:05.678901Z",
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
              coverFile: FileDescriptor(
                fdPath: "remote.php/dav/files/admin/test1.jpg",
                fdId: 1,
                fdMime: null,
                fdIsFavorite: false,
                fdIsArchived: false,
                fdDateTime: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
              ),
            ),
            sortProvider: const AlbumNullSortProvider(),
          ),
        );
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
              coverProvider: const AlbumAutoCoverProvider(),
              sortProvider: const AlbumTimeSortProvider(
                isAscending: true,
              ),
            ));
      });

      test("AlbumFilenameSortProvider", () {
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
            "type": "filename",
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
              coverProvider: const AlbumAutoCoverProvider(),
              sortProvider: const AlbumFilenameSortProvider(
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
              coverProvider: const AlbumAutoCoverProvider(),
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
          coverProvider: const AlbumAutoCoverProvider(),
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
          coverProvider: const AlbumAutoCoverProvider(),
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
            coverProvider: const AlbumAutoCoverProvider(),
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
            coverProvider: const AlbumAutoCoverProvider(),
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
            coverFile: FileDescriptor(
              fdPath: "remote.php/dav/files/admin/test1.jpg",
              fdId: 1,
              fdMime: null,
              fdIsFavorite: false,
              fdIsArchived: false,
              fdDateTime: DateTime.utc(2020, 1, 2, 3, 4, 5),
            ),
          ),
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
                "fdPath": "remote.php/dav/files/admin/test1.jpg",
                "fdId": 1,
                "fdMime": null,
                "fdIsArchived": false,
                "fdIsFavorite": false,
                "fdDateTime": "2020-01-02T03:04:05.000Z",
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
          coverProvider: const AlbumAutoCoverProvider(),
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

      test("AlbumFilenameSortProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: const AlbumAutoCoverProvider(),
          sortProvider: const AlbumFilenameSortProvider(
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
            "type": "filename",
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
          coverProvider: const AlbumAutoCoverProvider(),
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
          coverProvider: const AlbumAutoCoverProvider(),
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
            coverProvider: const AlbumAutoCoverProvider(),
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
            coverProvider: const AlbumAutoCoverProvider(),
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
            coverFile: FileDescriptor(
              fdPath: "remote.php/dav/files/admin/test1.jpg",
              fdId: 1,
              fdMime: null,
              fdIsFavorite: false,
              fdIsArchived: false,
              fdDateTime: DateTime.utc(2020, 1, 2, 3, 4, 5),
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
                "fdPath": "remote.php/dav/files/admin/test1.jpg",
                "fdId": 1,
                "fdMime": null,
                "fdIsArchived": false,
                "fdIsFavorite": false,
                "fdDateTime": "2020-01-02T03:04:05.000Z",
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
          coverProvider: const AlbumAutoCoverProvider(),
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

      test("AlbumFilenameSortProvider", () {
        final album = Album(
          lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
          name: "",
          provider: AlbumStaticProvider(
            items: [],
          ),
          coverProvider: const AlbumAutoCoverProvider(),
          sortProvider: const AlbumFilenameSortProvider(
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
            "type": "filename",
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
          coverProvider: const AlbumAutoCoverProvider(),
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
      expect(AlbumUpgraderV1().doJson(json), <String, dynamic>{
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
      expect(AlbumUpgraderV2().doJson(json), <String, dynamic>{
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
      expect(AlbumUpgraderV3().doJson(json), <String, dynamic>{
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
        expect(AlbumUpgraderV4().doJson(json), <String, dynamic>{
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
          expect(AlbumUpgraderV4().doJson(json), <String, dynamic>{
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
          expect(AlbumUpgraderV4().doJson(json), <String, dynamic>{
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
          expect(AlbumUpgraderV4().doJson(json), <String, dynamic>{
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
          expect(AlbumUpgraderV4().doJson(json), <String, dynamic>{
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
      final account = util.buildAccount(userId: "user1");

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
        expect(AlbumUpgraderV5(account).doJson(json), <String, dynamic>{
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
        expect(AlbumUpgraderV5(account).doJson(json), <String, dynamic>{
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
        expect(AlbumUpgraderV5(account).doJson(json), <String, dynamic>{
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
            AlbumUpgraderV5(account, albumFile: albumFile).doJson(json),
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

    group("AlbumUpgraderV8", () {
      group("doJson", () {
        test("non manual cover", _upgradeV8JsonNonManualCover);

        group("manual cover", () {
          test("now", _upgradeV8JsonManualNow);
          test("exif time", _upgradeV8JsonManualExifTime);
        });

        group("auto cover", () {
          test("null", _upgradeV8JsonAutoNull);
          test("last modified", _upgradeV8JsonAutoLastModified);
        });
      });

      group("doDb", () {
        test("non manual cover", _upgradeV8DbNonManualCover);

        group("manual cover", () {
          test("now", _upgradeV8DbManualNow);
          test("exif time", _upgradeV8DbManualExifTime);
        });

        group("auto cover", () {
          test("null", _upgradeV8DbAutoNull);
          test("last modified", _upgradeV8DbAutoLastModified);
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
        coverProvider: const AlbumAutoCoverProvider(),
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
    coverProvider: const AlbumAutoCoverProvider(),
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
    coverProvider: const AlbumAutoCoverProvider(),
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

void _upgradeV8JsonNonManualCover() {
  final json = <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
    "provider": <String, dynamic>{
      "type": "static",
      "content": <String, dynamic>{
        "items": [],
      },
    },
    "coverProvider": <String, dynamic>{
      "type": "memory",
      "content": <String, dynamic>{
        "coverFile": <String, dynamic>{
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          "fdDateTime": "2020-01-02T03:04:05.678901Z",
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  };
  expect(const AlbumUpgraderV8().doJson(json), <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
    "provider": <String, dynamic>{
      "type": "static",
      "content": <String, dynamic>{
        "items": [],
      },
    },
    "coverProvider": <String, dynamic>{
      "type": "memory",
      "content": <String, dynamic>{
        "coverFile": <String, dynamic>{
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          "fdDateTime": "2020-01-02T03:04:05.678901Z",
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  });
}

void _upgradeV8JsonManualNow() {
  withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () {
    final json = <String, dynamic>{
      "version": 8,
      "lastUpdated": "2020-01-02T03:04:05.678901Z",
      "provider": <String, dynamic>{
        "type": "static",
        "content": <String, dynamic>{
          "items": [],
        },
      },
      "coverProvider": <String, dynamic>{
        "type": "manual",
        "content": <String, dynamic>{
          "coverFile": <String, dynamic>{
            "path": "remote.php/dav/files/admin/test1.jpg",
            "fileId": 1,
          },
        },
      },
      "sortProvider": <String, dynamic>{
        "type": "null",
        "content": <String, dynamic>{},
      },
      "albumFile": <String, dynamic>{
        "path": "remote.php/dav/files/admin/test1.json",
      },
    };
    expect(const AlbumUpgraderV8().doJson(json), <String, dynamic>{
      "version": 8,
      "lastUpdated": "2020-01-02T03:04:05.678901Z",
      "provider": <String, dynamic>{
        "type": "static",
        "content": <String, dynamic>{
          "items": [],
        },
      },
      "coverProvider": <String, dynamic>{
        "type": "manual",
        "content": <String, dynamic>{
          "coverFile": <String, dynamic>{
            "fdPath": "remote.php/dav/files/admin/test1.jpg",
            "fdId": 1,
            "fdMime": null,
            "fdIsArchived": false,
            "fdIsFavorite": false,
            "fdDateTime": "2020-01-02T03:04:05.000Z",
          },
        },
      },
      "sortProvider": <String, dynamic>{
        "type": "null",
        "content": <String, dynamic>{},
      },
      "albumFile": <String, dynamic>{
        "path": "remote.php/dav/files/admin/test1.json",
      },
    });
  });
}

void _upgradeV8JsonManualExifTime() {
  final json = <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
    "provider": <String, dynamic>{
      "type": "static",
      "content": <String, dynamic>{
        "items": [],
      },
    },
    "coverProvider": <String, dynamic>{
      "type": "manual",
      "content": <String, dynamic>{
        "coverFile": <String, dynamic>{
          "path": "remote.php/dav/files/admin/test1.jpg",
          "fileId": 1,
          "metadata": <String, dynamic>{
            "exif": <String, dynamic>{
              "DateTimeOriginal": "2020:01:02 03:04:05",
            },
          },
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  };
  expect(const AlbumUpgraderV8().doJson(json), <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
    "provider": <String, dynamic>{
      "type": "static",
      "content": <String, dynamic>{
        "items": [],
      },
    },
    "coverProvider": <String, dynamic>{
      "type": "manual",
      "content": <String, dynamic>{
        "coverFile": <String, dynamic>{
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          // dart does not provide a way to mock timezone
          "fdDateTime": DateTime(2020, 1, 2, 3, 4, 5).toUtc().toIso8601String(),
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  });
}

void _upgradeV8JsonAutoNull() {
  final json = <String, dynamic>{
    "version": 8,
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
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  };
  expect(const AlbumUpgraderV8().doJson(json), <String, dynamic>{
    "version": 8,
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
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  });
}

void _upgradeV8JsonAutoLastModified() {
  final json = <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
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
          "fileId": 1,
          "lastModified": "2020-01-02T03:04:05.000Z",
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  };
  expect(const AlbumUpgraderV8().doJson(json), <String, dynamic>{
    "version": 8,
    "lastUpdated": "2020-01-02T03:04:05.678901Z",
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
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          "fdDateTime": "2020-01-02T03:04:05.000Z",
        },
      },
    },
    "sortProvider": <String, dynamic>{
      "type": "null",
      "content": <String, dynamic>{},
    },
    "albumFile": <String, dynamic>{
      "path": "remote.php/dav/files/admin/test1.json",
    },
  });
}

void _upgradeV8DbNonManualCover() {
  final dbObj = sql.Album(
    rowId: 1,
    file: 1,
    fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
    version: 8,
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test1",
    providerType: "static",
    providerContent: """{"items": []}""",
    coverProviderType: "memory",
    coverProviderContent: _stripJsonString("""{
      "coverFile": {
        "fdPath": "remote.php/dav/files/admin/test1.jpg",
        "fdId": 1,
        "fdMime": null,
        "fdIsArchived": false,
        "fdIsFavorite": false,
        "fdDateTime": "2020-01-02T03:04:05.678901Z"
      }
    }"""),
    sortProviderType: "null",
    sortProviderContent: "{}",
  );
  expect(
    const AlbumUpgraderV8().doDb(dbObj),
    sql.Album(
      rowId: 1,
      file: 1,
      fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
      version: 8,
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test1",
      providerType: "static",
      providerContent: """{"items": []}""",
      coverProviderType: "memory",
      coverProviderContent: _stripJsonString("""{
        "coverFile": {
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          "fdDateTime": "2020-01-02T03:04:05.678901Z"
        }
      }"""),
      sortProviderType: "null",
      sortProviderContent: "{}",
    ),
  );
}

void _upgradeV8DbManualNow() {
  withClock(Clock.fixed(DateTime.utc(2020, 1, 2, 3, 4, 5)), () {
    final dbObj = sql.Album(
      rowId: 1,
      file: 1,
      fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
      version: 8,
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test1",
      providerType: "static",
      providerContent: """{"items": []}""",
      coverProviderType: "manual",
      coverProviderContent: _stripJsonString("""{
        "coverFile": {
          "path": "remote.php/dav/files/admin/test1.jpg",
          "fileId": 1
        }
      }"""),
      sortProviderType: "null",
      sortProviderContent: "{}",
    );
    expect(
      const AlbumUpgraderV8().doDb(dbObj),
      sql.Album(
        rowId: 1,
        file: 1,
        fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
        version: 8,
        lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
        name: "test1",
        providerType: "static",
        providerContent: """{"items": []}""",
        coverProviderType: "manual",
        coverProviderContent: _stripJsonString("""{
          "coverFile": {
            "fdPath": "remote.php/dav/files/admin/test1.jpg",
            "fdId": 1,
            "fdMime": null,
            "fdIsArchived": false,
            "fdIsFavorite": false,
            "fdDateTime": "2020-01-02T03:04:05.000Z"
          }
        }"""),
        sortProviderType: "null",
        sortProviderContent: "{}",
      ),
    );
  });
}

void _upgradeV8DbManualExifTime() {
  final dbObj = sql.Album(
    rowId: 1,
    file: 1,
    fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
    version: 8,
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test1",
    providerType: "static",
    providerContent: """{"items": []}""",
    coverProviderType: "manual",
    coverProviderContent: _stripJsonString("""{
      "coverFile": {
        "path": "remote.php/dav/files/admin/test1.jpg",
        "fileId": 1,
        "metadata": {
          "exif": {
            "DateTimeOriginal": "2020:01:02 03:04:05"
          }
        }
      }
    }"""),
    sortProviderType: "null",
    sortProviderContent: "{}",
  );
  // dart does not provide a way to mock timezone
  final dateTime = DateTime(2020, 1, 2, 3, 4, 5).toUtc().toIso8601String();
  expect(
    const AlbumUpgraderV8().doDb(dbObj),
    sql.Album(
      rowId: 1,
      file: 1,
      fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
      version: 8,
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test1",
      providerType: "static",
      providerContent: """{"items": []}""",
      coverProviderType: "manual",
      coverProviderContent: _stripJsonString("""{
        "coverFile": {
          "fdPath": "remote.php/dav/files/admin/test1.jpg",
          "fdId": 1,
          "fdMime": null,
          "fdIsArchived": false,
          "fdIsFavorite": false,
          "fdDateTime": "$dateTime"
        }
      }"""),
      sortProviderType: "null",
      sortProviderContent: "{}",
    ),
  );
}

void _upgradeV8DbAutoNull() {
  final dbObj = sql.Album(
    rowId: 1,
    file: 1,
    fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
    version: 8,
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test1",
    providerType: "static",
    providerContent: """{"items": []}""",
    coverProviderType: "auto",
    coverProviderContent: "{}",
    sortProviderType: "null",
    sortProviderContent: "{}",
  );
  expect(
    const AlbumUpgraderV8().doDb(dbObj),
    sql.Album(
      rowId: 1,
      file: 1,
      fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
      version: 8,
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test1",
      providerType: "static",
      providerContent: """{"items": []}""",
      coverProviderType: "auto",
      coverProviderContent: "{}",
      sortProviderType: "null",
      sortProviderContent: "{}",
    ),
  );
}

void _upgradeV8DbAutoLastModified() {
  final dbObj = sql.Album(
    rowId: 1,
    file: 1,
    fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
    version: 8,
    lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
    name: "test1",
    providerType: "static",
    providerContent: """{"items": []}""",
    coverProviderType: "auto",
    coverProviderContent: _stripJsonString("""{
      "coverFile": {
        "path": "remote.php/dav/files/admin/test1.jpg",
        "fileId": 1,
        "lastModified": "2020-01-02T03:04:05.000Z"
      }
    }"""),
    sortProviderType: "null",
    sortProviderContent: "{}",
  );
  expect(
    const AlbumUpgraderV8().doDb(dbObj),
    sql.Album(
      rowId: 1,
      file: 1,
      fileEtag: "8a3e0799b6f0711c23cc2d93950eceb5",
      version: 8,
      lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5),
      name: "test1",
      providerType: "static",
      providerContent: """{"items": []}""",
      coverProviderType: "auto",
      coverProviderContent: _stripJsonString("""{
      "coverFile": {
        "fdPath": "remote.php/dav/files/admin/test1.jpg",
        "fdId": 1,
        "fdMime": null,
        "fdIsArchived": false,
        "fdIsFavorite": false,
        "fdDateTime": "2020-01-02T03:04:05.000Z"
      }
    }"""),
      sortProviderType: "null",
      sortProviderContent: "{}",
    ),
  );
}

String _stripJsonString(String str) {
  return jsonEncode(jsonDecode(str));
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
  @override
  buildV7() => null;
  @override
  AlbumUpgraderV8? buildV8() => null;
}
