import 'package:url_launcher/url_launcher_string.dart';

Future<bool> launch(String url) =>
    launchUrlString(url, mode: LaunchMode.externalApplication);
