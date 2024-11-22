part of 'service.dart';

class ServiceConfig {
  static Future<bool> isProcessExifWifiOnly() async {
    return Preference.getBool(_pref, _prefProcessWifiOnly, true)
        .notNull();
  }

  static Future<void> setProcessExifWifiOnly(bool flag) async {
    await Preference.setBool(_pref, _prefProcessWifiOnly, flag);
  }

  static const _pref = "service";
  static const _prefProcessWifiOnly = "shouldProcessWifiOnly";
}