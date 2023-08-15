import 'package:build/build.dart';
import 'package:np_codegen_build/src/drift_table_sort_generator.dart';
import 'package:np_codegen_build/src/np_log_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder driftTableSortBuilder(BuilderOptions options) =>
    SharedPartBuilder([const DriftTableSortGenerator()], "drift_table_sort");

Builder npLogBuilder(BuilderOptions options) =>
    SharedPartBuilder([const NpLogGenerator()], "np_log");
