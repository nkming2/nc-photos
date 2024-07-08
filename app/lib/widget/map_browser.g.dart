// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_browser.dart';

// **************************************************************************
// CopyWithLintRuleGenerator
// **************************************************************************

// ignore_for_file: library_private_types_in_public_api, duplicate_ignore

// **************************************************************************
// CopyWithGenerator
// **************************************************************************

abstract class $_StateCopyWithWorker {
  _State call(
      {List<_DataPoint>? data,
      LatLng? initialPoint,
      Set<Marker>? markers,
      ExceptionEvent? error});
}

class _$_StateCopyWithWorkerImpl implements $_StateCopyWithWorker {
  _$_StateCopyWithWorkerImpl(this.that);

  @override
  _State call(
      {dynamic data,
      dynamic initialPoint = copyWithNull,
      dynamic markers,
      dynamic error = copyWithNull}) {
    return _State(
        data: data as List<_DataPoint>? ?? that.data,
        initialPoint: initialPoint == copyWithNull
            ? that.initialPoint
            : initialPoint as LatLng?,
        markers: markers as Set<Marker>? ?? that.markers,
        error: error == copyWithNull ? that.error : error as ExceptionEvent?);
  }

  final _State that;
}

extension $_StateCopyWith on _State {
  $_StateCopyWithWorker get copyWith => _$copyWith;
  $_StateCopyWithWorker get _$copyWith => _$_StateCopyWithWorkerImpl(this);
}

// **************************************************************************
// NpLogGenerator
// **************************************************************************

extension _$_BlocNpLog on _Bloc {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("widget.map_browser._Bloc");
}

// **************************************************************************
// ToStringGenerator
// **************************************************************************

extension _$_StateToString on _State {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_State {data: [length: ${data.length}], initialPoint: $initialPoint, markers: {length: ${markers.length}}, error: $error}";
  }
}

extension _$_InitToString on _Init {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_Init {}";
  }
}

extension _$_SetMarkersToString on _SetMarkers {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetMarkers {markers: {length: ${markers.length}}}";
  }
}

extension _$_SetErrorToString on _SetError {
  String _$toString() {
    // ignore: unnecessary_string_interpolations
    return "_SetError {error: $error, stackTrace: $stackTrace}";
  }
}
