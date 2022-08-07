/// Covert all symbols to whitespace
String cleanUpSymbols(String s) =>
    s.replaceAll(RegExp(r"(?:_|[^\p{L}\d])+", unicode: true), " ");
