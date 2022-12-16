// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_local_dir.dart';

// **************************************************************************
// NpLogGenerator
// **************************************************************************

// ignore: non_constant_identifier_names
final _$logScanLocalDirBloc = Logger("bloc.scan_local_dir.ScanLocalDirBloc");

extension _$ScanLocalDirBlocNpLog on ScanLocalDirBloc {
  // ignore: unused_element
  Logger get _log => _$logScanLocalDirBloc;
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$ScanLocalDirBlocQueryToString on ScanLocalDirBlocQuery {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ScanLocalDirBlocQuery {relativePaths: ${relativePaths.toReadableString()}}";
  }
}

extension _$_ScanLocalDirBlocFileDeletedToString
    on _ScanLocalDirBlocFileDeleted {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_ScanLocalDirBlocFileDeleted {files: ${files.map((f) => f.logTag).toReadableString()}}";
  }
}

extension _$ScanLocalDirBlocStateToString on ScanLocalDirBlocState {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "${objectRuntimeType(this, "ScanLocalDirBlocState")} {files: [length: ${files.length}]}";
  }
}

extension _$ScanLocalDirBlocFailureToString on ScanLocalDirBlocFailure {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "ScanLocalDirBlocFailure {files: [length: ${files.length}], exception: $exception}";
  }
}
