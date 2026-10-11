import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' as m;

import '../theme/app_theme.dart';

class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.items,
    required this.columns,
    required this.cells,
    required this.mobileCard,
  });
  final List<T> items;
  final List<String> columns;
  final List<Widget> Function(T) cells;
  final Widget Function(T) mobileCard;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth < AppBreakpoints.compact
        ? Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: mobileCard(item),
                ),
            ],
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: m.DataTable(
              columns: columns
                  .map((label) => m.DataColumn(label: Text(label)))
                  .toList(),
              rows: items
                  .map(
                    (item) => m.DataRow(
                      cells: cells(item)
                          .map((cell) => m.DataCell(cell))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
  );
}
