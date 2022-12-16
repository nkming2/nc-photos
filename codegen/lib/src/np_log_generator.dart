import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:np_codegen/src/np_log_annotations.dart';
import 'package:source_gen/source_gen.dart';

/// Add a properly tagged logger to a class or extension
///
/// If used with extension, the extension and the extended class must be in
/// separated file
class NpLogGenerator extends GeneratorForAnnotation<NpLog> {
  const NpLogGenerator();

  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is ClassElement) {
      final clazz = element;
      return """
// ignore: non_constant_identifier_names
final _\$log${clazz.name} = Logger("${_buildLogTag(clazz)}");

extension _\$${clazz.name}NpLog on ${clazz.name} {
  // ignore: unused_element
  Logger get _log => _\$log${clazz.name};
}
""";
    } else if (element is ExtensionElement) {
      final extension = element;
      return """
// ignore: non_constant_identifier_names
final _\$log${extension.name} = Logger("${_buildLogTag(extension)}");

extension _\$${extension.name}NpLog on ${extension.extendedType.element2!.name} {
  // ignore: unused_element
  Logger get _log => _\$log${extension.name};
}
""";
    } else {
      print("Only class/extension is supported");
      return null;
    }
  }

  String _buildLogTag(Element clazz) {
    // a path looks like this: package:super/my/secret/source.dart
    final path = clazz.library!.identifier;
    // my/secret/source.dart
    final relativePath = path.substring(path.indexOf("/") + 1);
    final extSearchFrom = relativePath.lastIndexOf("/") + 1;
    final extI = relativePath.indexOf(".", extSearchFrom);
    // my.secret.source
    final prefix = relativePath.substring(0, extI).replaceAll("/", ".");
    return "$prefix.${clazz.name}";
  }
}
