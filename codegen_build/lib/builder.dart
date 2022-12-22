import 'package:build/build.dart';
import 'package:np_codegen_build/src/np_log_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder npLogBuilder(BuilderOptions options) =>
    SharedPartBuilder([NpLogGenerator()], "np_log");
