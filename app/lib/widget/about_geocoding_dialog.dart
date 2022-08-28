import 'package:flutter/material.dart';
import 'package:nc_photos/app_localizations.dart';
import 'package:nc_photos/theme.dart';

class AboutGeocodingDialog extends StatelessWidget {
  const AboutGeocodingDialog({
    Key? key,
  }) : super(key: key);

  @override
  build(BuildContext context) {
    return AppTheme(
      child: AlertDialog(
        title: Text(L10n.global().gpsPlaceAboutDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.global().gpsPlaceAboutDialogContent),
            const SizedBox(height: 16),
            const Divider(height: 16),
            const Text(
              "Based on GeoNames Gazetteer data by GeoNames, licensed under CC BY 4.0",
            ),
          ],
        ),
      ),
    );
  }
}
