part of 'home_photos.dart';

@toString
class _SectionLayout {
  const _SectionLayout({
    required this.date,
    required this.logicalY,
    required this.logicalHeight,
    required this.itemCount,
    required this.rowCount,
  });

  @override
  String toString() => _$toString();

  final Date date;
  final double logicalY;
  final double logicalHeight;
  final int itemCount;
  final int rowCount;
}

class _MinimapItem {
  const _MinimapItem({
    required this.date,
    required this.logicalY,
    required this.logicalHeight,
  });

  final Date date;
  final double logicalY;
  final double logicalHeight;
}

class _LayoutSummary {
  const _LayoutSummary({
    required this.sectionLayouts,
    required this.minimapItems,
  });

  final List<_SectionLayout> sectionLayouts;
  final List<_MinimapItem> minimapItems;
}

/// Summarize section layout data for minimap, scrolling, etc...
@npLog
class _LayoutSummarizer {
  _LayoutSummary summarize({
    required List<List<_Item>> transformedItems,
    required bool isSectionGroupedByMonth,
    required double itemSize,
    required int itemPerRow,
    required double dateHeight,
  }) {
    if (isSectionGroupedByMonth) {
      return _byMonthSections(
        transformedItems: transformedItems,
        itemSize: itemSize,
        itemPerRow: itemPerRow,
        dateHeight: dateHeight,
      );
    } else {
      return _byDaySections(
        transformedItems: transformedItems,
        itemSize: itemSize,
        itemPerRow: itemPerRow,
        dateHeight: dateHeight,
      );
    }
  }

  _LayoutSummary _byMonthSections({
    required List<List<_Item>> transformedItems,
    required double itemSize,
    required int itemPerRow,
    required double dateHeight,
  }) {
    _log.info(
      "[_byMonthSections] itemSize: $itemSize, itemPerRow: $itemPerRow",
    );
    double position = 0;
    final minimapItems = <_MinimapItem>[];
    final sectionLayouts = <_SectionLayout>[];
    for (final section in transformedItems) {
      final header = section.first as _SectionHeaderItem;
      final itemCount = section.length - 1;
      final rowCount = (itemCount / itemPerRow).ceil();
      final h = dateHeight + rowCount * itemSize;
      sectionLayouts.add(
        _SectionLayout(
          date: header.date,
          itemCount: itemCount,
          logicalY: position,
          rowCount: rowCount,
          logicalHeight: h,
        ),
      );
      minimapItems.add(
        _MinimapItem(date: header.date, logicalY: position, logicalHeight: h),
      );
      position += h;
    }
    return _LayoutSummary(
      sectionLayouts: sectionLayouts,
      minimapItems: minimapItems,
    );
  }

  _LayoutSummary _byDaySections({
    required List<List<_Item>> transformedItems,
    required double itemSize,
    required int itemPerRow,
    required double dateHeight,
  }) {
    _log.info("[_byDaySections] itemSize: $itemSize, itemPerRow: $itemPerRow");
    double position = 0;
    Date? currentMonth;
    double currentMonthY = 0;
    double currentMonthHeight = 0;
    final minimapItems = <_MinimapItem>[];
    final sectionLayouts = <_SectionLayout>[];
    for (final section in transformedItems) {
      final header = section.first as _SectionHeaderItem;
      final itemCount = section.length - 1;
      final rowCount = (itemCount / itemPerRow).ceil();
      final h = dateHeight + rowCount * itemSize;
      sectionLayouts.add(
        _SectionLayout(
          date: header.date,
          itemCount: itemCount,
          logicalY: position,
          rowCount: rowCount,
          logicalHeight: h,
        ),
      );

      final thisMonth = Date(header.date.year, header.date.month);
      if (currentMonth != thisMonth) {
        if (currentMonth != null) {
          minimapItems.add(
            _MinimapItem(
              date: currentMonth,
              logicalY: currentMonthY,
              logicalHeight: currentMonthHeight,
            ),
          );
        }
        currentMonth = thisMonth;
        currentMonthY = position;
        currentMonthHeight = h;
      } else {
        currentMonthHeight += h;
      }
      position += h;
    }
    // add the last month
    if (currentMonth != null) {
      minimapItems.add(
        _MinimapItem(
          date: currentMonth,
          logicalY: currentMonthY,
          logicalHeight: currentMonthHeight,
        ),
      );
    }
    return _LayoutSummary(
      sectionLayouts: sectionLayouts,
      minimapItems: minimapItems,
    );
  }
}
