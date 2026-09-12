part of 'changelog.dart';

class _Changelog920 extends StatelessWidget {
  const _Changelog920();

  @override
  Widget build(BuildContext context) {
    final s = _str(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSection(s.sectionChange),
        _bulletGroup(Text(s.sectionChange1)),
        _bulletGroup(Text(s.sectionChange2)),
        _bulletGroup(Text(s.sectionChange3)),
      ],
    );
  }

  _Changelog920Str _str(BuildContext context) {
    if (Localizations.localeOf(context).languageCode == "ja") {
      return const _Changelog920StrJa();
    } else {
      return const _Changelog920Str();
    }
  }
}

class _Changelog920Str {
  const _Changelog920Str();

  String get sectionChange => "Changes";
  String get sectionChange1 =>
      "Added pen tool to image editor for drawing on images";
  String get sectionChange2 =>
      "Switched the default HTTP engine to Chromium. It will fall back to the old engine automatically when your server uses a self-signed certificate";
  String get sectionChange3 => "Optimized performance of the photos timeline";
}

class _Changelog920StrJa implements _Changelog920Str {
  const _Changelog920StrJa();

  @override
  String get sectionChange => "主な更新内容";
  @override
  String get sectionChange1 => "画像エディタにペンツールを追加しました";
  @override
  String get sectionChange2 =>
      "デフォルトのHTTPエンジンをChromiumに変更しました。また、自己署名証明書を使っているサーバーに接続する場合は、自動的に古いHTTPエンジンに切り替わるようになりました";
  @override
  String get sectionChange3 => "タイムラインのパフォーマンスを改善しました";
}
