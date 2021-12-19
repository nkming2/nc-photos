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
