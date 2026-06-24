import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';

class AppMasonryGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;
  final int? minColumns;
  final int? maxColumns;

  const AppMasonryGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.spacing = AppSizes.paddingSmall,
    this.minColumns,
    this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final baseColumns = width >= 900
            ? 4
            : width >= 640
            ? 3
            : 2;
        final columnCount = baseColumns
            .clamp(minColumns ?? 2, maxColumns ?? 4)
            .toInt();
        final columns = List.generate(columnCount, (_) => <Widget>[]);

        for (var index = 0; index < itemCount; index += 1) {
          final column = columns[index % columnCount];
          if (column.isNotEmpty) {
            column.add(SizedBox(height: spacing));
          }
          column.add(itemBuilder(context, index));
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < columns.length; index += 1) ...[
              if (index > 0) SizedBox(width: spacing),
              Expanded(child: Column(children: columns[index])),
            ],
          ],
        );
      },
    );
  }
}
