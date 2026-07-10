part of 'changelog.dart';

class _Changelog910 extends StatelessWidget {
  const _Changelog910();

  @override
  Widget build(BuildContext context) {
    final s = _str(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSectionHighlight(s.sectionImportant),
        _bulletGroup(Text(s.sectionImportant1)),
        _subSection(s.sectionChange),
        _bulletGroup(Text(s.sectionChange1), [
          Text(s.sectionChange1a),
          Text(s.sectionChange1b),
          Text(s.sectionChange1c),
          Text(s.sectionChange1d),
          Text(s.sectionChange1e),
          Text(s.sectionChange1f),
        ]),
        _bulletGroup(Text(s.sectionChange2)),
        _sectionPadding(),
        _subSection(s.sectionContributor),
        _bulletGroup(Text("${s.sectionContributor1} \u{1f44f}"), [
          const Text("Ali Yasin Yeşilyaprak"),
          const Text("Corentin Noël"),
        ]),
      ],
    );
  }

  _Changelog910Str _str(BuildContext context) {
    if (Localizations.localeOf(context).languageCode == "ja") {
      return const _Changelog910StrJa();
    } else {
      return const _Changelog910Str();
    }
  }
}

class _Changelog910Str {
  const _Changelog910Str();

  String get sectionImportant => "Important";
  String get sectionImportant1 =>
      "32-bit Android devices are no longer supported";

  String get sectionChange => "Changes";
  String get sectionChange1 => "Image enhancer has been rewritten from scratch";
  String get sectionChange1a =>
      "No longer crashes due to Java memory constraints";
  String get sectionChange1b =>
      "Color Pop: you can now select the object to be focused";
  String get sectionChange1c => "Derain: new enhancement to remove rain";
  String get sectionChange1d => "Low Light: updated model weight";
  String get sectionChange1e =>
      "Portrait Blur: you can now select the object to be focused";
  String get sectionChange1f => "Super Resolution: switched to a new model";
  String get sectionChange2 => "Updated Turkish and Ukrainian translations";

  String get sectionContributor => "Contributors";
  String get sectionContributor1 =>
      "Special thanks to the following contributors";
}

class _Changelog910StrJa implements _Changelog910Str {
  const _Changelog910StrJa();

  @override
  String get sectionImportant => "重要";
  @override
  String get sectionImportant1 => "Android 32ビット端末のサポートを終了しました";

  @override
  String get sectionChange => "主な更新内容";
  @override
  String get sectionChange1 => "写真補正機能を書き直しました";
  @override
  String get sectionChange1a => "Javaのメモリ制約によるクラッシュがなくなりました";
  @override
  String get sectionChange1b => "カラーポップ：焦点に当たる部分を自分で指定できるようになりました";
  @override
  String get sectionChange1c => "雨除去：雨を消す機能を新しく追加しました";
  @override
  String get sectionChange1d => "低照度補正：AIモデルのウエイトを調整しました";
  @override
  String get sectionChange1e => "背景ぼかし：焦点に当たる部分を自分で指定できるようになりました";
  @override
  String get sectionChange1f => "超解像：新しいAIモデルに移行しました";
  @override
  String get sectionChange2 => "TurkishとUkrainianのローカライズを更新しました";

  @override
  String get sectionContributor => "貢献者";
  @override
  String get sectionContributor1 =>
      "このバージョンは下記の貢献者の皆さまのご協力により、無事リリースできました。ありがとうございました";
}
