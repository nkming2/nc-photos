import 'package:code_gen_tester/code_gen_tester.dart';
import 'package:np_codegen_build/src/np_log_generator.dart';
import 'package:test/test.dart';

// dummy class to free us from importing the actual logger library
class Logger {
  Logger(String name);
}

void main() {
  final tester = SourceGenTester.fromPath("test/src/np_log.dart");
  final generator = NpLogGenerator();
  Future<void> expectGen(String name, Matcher matcher) async =>
      expectGenerateNamed(await tester, name, generator, matcher);

  test("NpLog", () async {
    await expectGen("Test", completion("""
extension _\$TestNpLog on Test {
  // ignore: unused_element
  Logger get _log => log;

  static final log = Logger("np_log.Test");
}
"""));
  });
}
