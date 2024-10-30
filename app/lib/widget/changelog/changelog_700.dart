part of '../changelog.dart';

class _Changelog700 extends StatelessWidget {
  const _Changelog700();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subSection("Changes"),
        _bulletGroup(const Text("Updated Czech, German, Spanish")),
        _sectionPadding(),
        _subSection("Contributors"),
        _bulletGroup(
          const Text("Special thanks to the following contributors \u{1f44f}"),
          [
            const Text("Fjuro"),
            const Text("luckkmaxx"),
            const Text("Niclas Heinz"),
          ],
        ),
      ],
    );
  }
}
