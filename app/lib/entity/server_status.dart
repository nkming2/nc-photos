import 'package:to_string/to_string.dart';

part 'server_status.g.dart';

@toString
class ServerStatus {
  const ServerStatus({
    required this.versionRaw,
    required this.versionName,
    required this.productName,
  });

  @override
  String toString() => _$toString();

  final String versionRaw;
  final String versionName;
  final String productName;
}

extension ServerStatusExtension on ServerStatus {
  List<int> get versionNumber => versionRaw.split(".").map(int.parse).toList();
  int get majorVersion => versionNumber[0];
}
