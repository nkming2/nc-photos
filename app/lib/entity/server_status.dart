import 'package:equatable/equatable.dart';
import 'package:np_common/type.dart';
import 'package:to_string/to_string.dart';

part 'server_status.g.dart';

@toString
class ServerStatus with EquatableMixin {
  const ServerStatus({
    required this.versionRaw,
    required this.versionName,
    required this.productName,
  });

  @override
  String toString() => _$toString();

  factory ServerStatus.fromJson(JsonObj json) {
    return ServerStatus(
      versionRaw: json["versionRaw"],
      versionName: json["versionName"],
      productName: json["productName"],
    );
  }

  JsonObj toJson() {
    return {
      "versionRaw": versionRaw,
      "versionName": versionName,
      "productName": productName,
    };
  }

  @override
  List<Object?> get props => [versionRaw, versionName, productName];

  final String versionRaw;
  final String versionName;
  final String productName;
}

extension ServerStatusExtension on ServerStatus {
  List<int> get versionNumber => versionRaw.split(".").map(int.parse).toList();
  int get majorVersion => versionNumber[0];
}
