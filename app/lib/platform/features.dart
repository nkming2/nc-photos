import 'package:nc_photos/platform/k.dart' as platform_k;

final isSupportMapView = platform_k.isWeb || platform_k.isAndroid;
final isSupportSelfSignedCert = platform_k.isAndroid;
final isSupportEnhancement = platform_k.isAndroid;

const isSupportAds = !platform_k.isWeb;
