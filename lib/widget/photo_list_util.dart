import 'package:nc_photos/entity/file.dart';

class DateGroupHelper {
  DateGroupHelper({
    required this.isMonthOnly,
  });

  DateTime? onFile(File file) {
    final newDate = file.bestDateTime.toLocal();
    if (newDate.year != _currentDate?.year ||
        newDate.month != _currentDate?.month ||
        (!isMonthOnly && newDate.day != _currentDate?.day)) {
      _currentDate = newDate;
      return newDate;
    }
  }

  final bool isMonthOnly;
  DateTime? _currentDate;
}

int getThumbSize(int zoomLevel) {
  switch (zoomLevel) {
    case -1:
      return 96;

    case 1:
      return 176;

    case 2:
      return 256;

    case 0:
    default:
      return 112;
  }
}
