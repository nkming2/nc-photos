# Localization

Each file stores the localized strings for a single language. The file is named with the corresponding ISO language code (e.g., app_**en**.arb for English). For languages with variants, an optional script code and/or country code may be followed (e.g., app_zh_**Hans**.arb, app_zh_**Hant**.arb). Check out the [flutter documentation](https://flutter.dev/docs/development/accessibility-and-localization/internationalization#advanced-topics-for-further-customization) for more details.

## Help with translations

Each item in an ARB file is formatted like the following.
```
"exampleString": "Hello World",
"@exampleString": {
	"description": "An example string"
}
```
In the above example, only the `"Hello World"` part needs to be translated. `exampleString` is the key used to access this string and must not be modified. The `@exampleString` block provides metadata for this string and is only intended to be read by the translators, it's not necessary to be translated either.

### For a new language

`app_en.arb` contains all strings that needed to be localized.

### For an existing language

`untranslated-messages.txt` contains a list of untranslated strings for each language.
