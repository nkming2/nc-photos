const contents = [
  // v1
  null,
  // v2
  null,
  // v3
  null,
  // v4
  null,
  // v5
  null,
  // v6
  null,
  // v7
  """1.7.0
Added HEIC support
Fixed a bug that corrupted the albums. Please re-add the photos after upgrading. Sorry for your inconvenience
""",
  // v8
  """1.8.0
Dark theme
""",
  // v9
  null,
  // v10
  null,
  // v11
  null,
  // v12
  null,
  // v13
  """13.0
Added MP4 support (Android only)
""",
  // v14
  null,
  // v15
  """15.0
This version includes changes that are not compatible with older versions. Please also update your other devices if applicable
""",
  // v16
  null,
  // v17
  """17.0
Archive photos to only show them in albums
Link to report issues in Settings
""",
  // v18
  """18.0
Modify date/time of photos
Support GIF
""",
  // v19
  """19.0
- Folder based album to browse photos in an existing folder (read only)
- Batch import folder based albums

This version includes changes that are not compatible with older versions. Please also update your other devices if applicable
""",
  // v20
  """20.0
- Improved albums: sorting, text labels
- Simplify sharing to other apps
- Added WebM support (Android only)
""",
  // v21
  null,
  // v22
  null,
  // v23
  """23.0
- Paid version is now published on Play Store. Head to Settings to learn more if you are interested
""",
  // v24
  """24.0
- Show and manage deleted files in trash bin
""",
  // v25
  null,
  // v26
  """26.0
- Pick album cover (open a photo in an album -> details -> use as cover)
""",
  // v27
  """27.0
- New settings to customize photo viewer
""",
  // v28
  """28.0
- New settings:
  - Follow system dark theme settings (Android 10+)
""",
  // v29
  """29.0
Features:
  - (Experimental) Support the Nextcloud Face Recognition app
  - Slideshow
  - Performance & cache tweaks
    - Due to an overhaul to the cache management, the old cache can't be used and will be cleared. First run after update will thus be slower

Localization (new/update):
  - German (by PhilProg)
  - Spanish (by luckkmaxx)
""",
  // v30
  """30.0
Features:
  - Share a single item using a link
  - Optimize albums: the JSON files are now much smaller
  - Download album/selected items

Localization (new/update):
  - Czech (by Skyhawk)
  - Spanish (by luckkmaxx)
""",
  // v31
  """31.0
Features:
  - Share multiple items using a link
  - Manage shares in Collections > Sharing
  - (Web) Now support share links like Android
  - Group photos by date in albums (enable in Settings > Album)
""",
  // v32
  """32.0
Features:
  - Enable/disable server app integrations in Settings > Account
""",
  // v33
  null,
  // v34
  """34.0
- Add OSM as an alternative map provider (Settings > Viewer)
- (Experimental) Add shared album (Settings > Experimental)
- (UI) Swipe up to show photo details
- (Localization) Update Spanish (by luckkmaxx)
""",
  // v35
  """35.0
- Optimize start up performance
  - Photos should appear more quickly on start up
- (UI) Swipe down to close the photo viewer
- (Localization) Add Finnish (by pHamala)

* The app needs to resync with the server due to changes in the database
""",
  // v36
  """36.0
- Memories
  - Show photos taken in the past
""",
  // v37
  """37.0
- Favorites
  - Browse favorites (Collections > Favorites)
  - Add to or remove from favorites in photo viewer
- Tag
  - Browse photos by specific tags (Collections > New collection > Tag)
- (Localization) Add Polish (by szymok)
- (Localization) Update Finnish (by pHamala)
""",
  // v38
  """38.0
- (Android) Image metadata are now processed in a background service
- (Localization) Update Finnish (by pHamala)
- (Localization) Update Spanish (by luckkmaxx)
""",
  // v39
  null,
  // v40
  """40.0
- (Android) Fixed a race condition causing the app to deadlock
- (Localization) Add Portuguese (by fernosan)
- (Localization) Update Finnish (by pHamala)
- (Localization) Update Russian (by kvasenok)
""",
  // v41
  """41.0
- (Android) Enhance your photo with the new Enhance button in viewer
- (Android) New photo enhancement algorithms:
  - Low-light enhancement
  - Portrait blur
- (Localization) Add Chinese (by zerolin)
- (Localization) Update French (by mgreil)
""",
  // v42
  """42.0
- Add tweakable parameters to low-light enhancement and portrait blur
""",
  // v43
  """43.0
- (Android) Photo enhancements now implemented in C++:
  - Better performance
  - Less restrictions on RAM usage
- (Android) New photo enhancement algorithms:
  - Super-resolution (upscale image to 4x)
- (Localization) Update Finnish (by pHamala)
""",
];
