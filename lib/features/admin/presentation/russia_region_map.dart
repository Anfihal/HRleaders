import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as s;

import '../../../core/components/app_components.dart';
import '../../../core/localization/localization.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/admin.dart';

/// Natural Earth public-domain country geometry. Keyboard users select the
/// same region metrics through buttons below the illustrative geographic map.
class RussiaRegionMap extends StatefulWidget {
  const RussiaRegionMap({super.key, required this.regions});
  final List<RegionMetric> regions;
  @override
  State<RussiaRegionMap> createState() => _RussiaRegionMapState();
}

class _RussiaRegionMapState extends State<RussiaRegionMap> {
  late final Future<List<List<Offset>>> _geometry = _load();
  RegionCode? _selected;
  Future<List<List<Offset>>> _load() async {
    final raw = jsonDecode(
      await rootBundle.loadString('assets/maps/russia.json'),
    ) as List;
    return [
      for (final polygon in raw)
        for (final ring in polygon as List)
          [
            for (final point in ring as List)
              Offset(
                (point[0] as num).toDouble() < 0
                    ? (point[0] as num).toDouble() + 360
                    : (point[0] as num).toDouble(),
                (point[1] as num).toDouble(),
              ),
          ],
    ];
  }

  String _label(BuildContext context, RegionCode region) => switch (region) {
    RegionCode.moscow => context.l.regionMoscow,
    RegionCode.petersburg => context.l.regionPetersburg,
    RegionCode.kazan => context.l.regionKazan,
    RegionCode.novosibirsk => context.l.regionNovosibirsk,
  };
  @override
  Widget build(BuildContext context) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FutureBuilder<List<List<Offset>>>(
          future: _geometry,
          builder: (context, snapshot) => AspectRatio(
            aspectRatio: 2.6,
            child: ExcludeSemantics(
              child: CustomPaint(
                painter: _RussiaPainter(
                  snapshot.data ?? const [],
                  s.Theme.of(context).colorScheme.muted,
                  s.Theme.of(context).colorScheme.border,
                  _selected,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final region in widget.regions)
              Semantics(
                selected: region.region == _selected,
                child: AppButton(
                  label:
                      '${_label(context, region.region)} · ${context.number(region.count)}',
                  secondary: region.region != _selected,
                  onPressed: () => setState(() => _selected = region.region),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}

class _RussiaPainter extends CustomPainter {
  _RussiaPainter(this.polygons, this.fill, this.border, this.selected);
  final List<List<Offset>> polygons;
  final Color fill, border;
  final RegionCode? selected;
  static const points = {
    RegionCode.moscow: Offset(37.62, 55.75),
    RegionCode.petersburg: Offset(30.31, 59.94),
    RegionCode.kazan: Offset(49.11, 55.79),
    RegionCode.novosibirsk: Offset(82.93, 55.01),
  };
  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / 165, size.height / 42);
    final origin = Offset(
      (size.width - 165 * scale) / 2,
      (size.height - 42 * scale) / 2,
    );
    Offset project(Offset p) =>
        origin + Offset((p.dx - 20) * scale, (83 - p.dy) * scale);
    for (final ring in polygons) {
      if (ring.isEmpty) continue;
      final path = Path()
        ..moveTo(project(ring.first).dx, project(ring.first).dy);
      for (final p in ring.skip(1)) {
        final projected = project(p);
        path.lineTo(projected.dx, projected.dy);
      }
      path.close();
      canvas.drawPath(path, Paint()..color = fill);
      canvas.drawPath(
        path,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    for (final entry in points.entries) {
      canvas.drawCircle(
        project(entry.value),
        entry.key == selected ? 7 : 4,
        Paint()
          ..color = entry.key == selected ? AppColors.danger : AppColors.brand,
      );
    }
  }

  @override
  bool shouldRepaint(_RussiaPainter oldDelegate) =>
      oldDelegate.polygons != polygons ||
      oldDelegate.selected != selected ||
      oldDelegate.fill != fill ||
      oldDelegate.border != border;
}
