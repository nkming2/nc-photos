import 'package:nc_photos/entity/album.dart';
import 'package:nc_photos/entity/album/cover_provider.dart';
import 'package:nc_photos/entity/album/item.dart';
import 'package:nc_photos/entity/album/provider.dart';
import 'package:nc_photos/entity/album/sort_provider.dart';
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
            Album.fromJson(json,
                upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
            Album.fromJson(json,
                upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
            "sortProvider": <String, dynamic>{
              "type": "null",
              "content": <String, dynamic>{},
            },
          };
          expect(
              Album.fromJson(json,
                  upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
              Album.fromJson(json,
                  upgraderV1: null, upgraderV2: null, upgraderV3: null),
              Album(
                lastUpdated: DateTime.utc(2020, 1, 2, 3, 4, 5, 678, 901),
                name: "",
                provider: AlbumStaticProvider(
                  items: [
                    AlbumLabelItem(
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
            Album.fromJson(json,
                upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
            Album.fromJson(json,
                upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
            Album.fromJson(json,
                upgraderV1: null, upgraderV2: null, upgraderV3: null),
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
                  file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
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
                  file: File(path: "remote.php/dav/files/admin/test1.jpg"),
                ),
                AlbumFileItem(
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
  });
}
