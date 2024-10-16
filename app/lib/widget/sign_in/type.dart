part of '../sign_in.dart';

enum _Scheme {
  http,
  https;

  String toValueString() {
    switch (this) {
      case http:
        return "http";

      case https:
        return "https";
    }
  }
}
