import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/expense_db.dart';

const categoryColors = <ExpenseCategory, Color>{
  ExpenseCategory.food: Color(0xFFEF6C00),
  ExpenseCategory.study: Color(0xFF1E88E5),
  ExpenseCategory.travel: Color(0xFF43A047),
  ExpenseCategory.gear: Color(0xFF8E24AA),
  ExpenseCategory.entertainment: Color(0xFFE53935),
  ExpenseCategory.bills: Color(0xFF00897B),
};

String formatVnd(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return '$b đ';
}

String _short(int v) => v >= 1000000
    ? '${(v / 1000000).toStringAsFixed(1)}M'
    : v >= 1000
        ? '${(v / 1000).round()}k'
        : '$v';

// ---------------------------------------------------------------- Donut

class CategoryDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, int> data;
  const CategoryDonutChart({super.key, required this.data});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..forward();
  int? _selected;

  @override
  void didUpdateWidget(covariant CategoryDonutChart old) {
    super.didUpdateWidget(old);
    if (old.data != widget.data) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTap(Offset local, Size size, List<MapEntry<ExpenseCategory, int>> e) {
    final c = size.center(Offset.zero);
    final d = local - c;
    final r = d.distance;
    final outer = size.shortestSide / 2;
    if (r < outer * 0.5 || r > outer) {
      setState(() => _selected = null);
      return;
    }
    var ang = math.atan2(d.dy, d.dx) + math.pi / 2; // 0 = 12h
    if (ang < 0) ang += 2 * math.pi;
    final total = e.fold<int>(0, (s, x) => s + x.value);
    var acc = 0.0;
    for (var i = 0; i < e.length; i++) {
      acc += e[i].value / total * 2 * math.pi;
      if (ang <= acc) {
        setState(() => _selected = _selected == i ? null : i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.data.entries.where((e) => e.value > 0).toList();
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final cs = Theme.of(context).colorScheme;

    if (total == 0) {
      return const SizedBox(height: 200, child: Center(child: Text('Chưa có dữ liệu')));
    }

    return Column(children: [
      AspectRatio(
        aspectRatio: 1.4,
        child: LayoutBuilder(builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return GestureDetector(
            onTapUp: (d) => _onTap(d.localPosition, size, entries),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => CustomPaint(
                size: size,
                painter: _DonutPainter(
                  entries: entries,
                  progress: Curves.easeOutCubic.transform(_ctrl.value),
                  selected: _selected,
                  textColor: cs.onSurface,
                  trackColor: cs.surfaceContainerHighest,
                  centerLabel: _selected == null
                      ? 'Tổng\n${formatVnd(total)}'
                      : '${entries[_selected!].key.label}\n${formatVnd(entries[_selected!].value)}',
                ),
              ),
            ),
          );
        }),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 16, runSpacing: 8, children: [
        for (final e in entries)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: categoryColors[e.key], shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('${e.key.label} ${(e.value / total * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall),
          ]),
      ]),
    ]);
  }
}

class _DonutPainter extends CustomPainter {
  final List<MapEntry<ExpenseCategory, int>> entries;
  final double progress;
  final int? selected;
  final Color textColor, trackColor;
  final String centerLabel;

  _DonutPainter({
    required this.entries,
    required this.progress,
    required this.selected,
    required this.textColor,
    required this.trackColor,
    required this.centerLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final stroke = radius * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius - stroke / 2 - 4);

    canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = trackColor);

    var start = -math.pi / 2;
    const gap = 0.02;
    for (var i = 0; i < entries.length; i++) {
      final full = entries[i].value / total * 2 * math.pi;
      final sweep = math.max(0.0, full * progress - gap);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = i == selected ? stroke + 10 : stroke
        ..color = categoryColors[entries[i].key]!;
      canvas.drawArc(rect, start + gap / 2, sweep, false, paint);

      // nhan phan tram tren cung (chi khi du rong)
      if (progress > 0.95 && full > 0.3) {
        final mid = start + full / 2;
        final p = center + Offset(math.cos(mid), math.sin(mid)) * rect.width / 2;
        _text(canvas, '${(entries[i].value / total * 100).round()}%', p,
            Colors.white, 11, bold: true);
      }
      start += full * progress;
    }

    _text(canvas, centerLabel, center, textColor, 13, bold: true);
  }

  void _text(Canvas c, String s, Offset at, Color col, double fs,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: col,
              fontSize: fs,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 120);
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _DonutPainter o) =>
      o.progress != progress ||
      o.selected != selected ||
      o.entries != entries ||
      o.textColor != textColor;
}

// ------------------------------------------------------------------ Bars

class WeeklyBarChart extends StatelessWidget {
  final List<({DateTime day, int total})> data;
  const WeeklyBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1.6,
      child: TweenAnimationBuilder<double>(
        key: ValueKey(data.map((e) => e.total).join(',')),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) => CustomPaint(
          painter: _BarPainter(
            data: data,
            progress: t,
            barColor: cs.primary,
            axisColor: cs.outline,
            textColor: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  final List<({DateTime day, int total})> data;
  final double progress;
  final Color barColor, axisColor, textColor;

  _BarPainter({
    required this.data,
    required this.progress,
    required this.barColor,
    required this.axisColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const left = 44.0, bottom = 28.0, top = 20.0;
    final chart = Rect.fromLTWH(left, top, size.width - left - 8, size.height - top - bottom);

    final maxV = math.max(1, data.fold<int>(0, (m, e) => math.max(m, e.total)));
    // lam tron max len bac "dep" de truc Y de doc
    final step = _niceStep(maxV / 4);
    final yMax = step * 4;

    final grid = Paint()
      ..color = axisColor.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = chart.bottom - chart.height * i / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), grid);
      _label(canvas, _short((step * i).round()), Offset(chart.left - 6, y),
          align: _A.right);
    }
    // truc X + truc Y
    final axis = Paint()
      ..color = axisColor
      ..strokeWidth = 1.5;
    canvas.drawLine(chart.bottomLeft, chart.bottomRight, axis);
    canvas.drawLine(chart.topLeft, chart.bottomLeft, axis);

    final slot = chart.width / data.length;
    final barW = slot * 0.55;
    final fill = Paint()..color = barColor;
    for (var i = 0; i < data.length; i++) {
      final cx = chart.left + slot * (i + 0.5);
      final h = chart.height * (data[i].total / yMax) * progress;
      final r = RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - barW / 2, chart.bottom - h, barW, h),
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      if (data[i].total > 0) canvas.drawRRect(r, fill);
      if (data[i].total > 0 && progress > 0.9) {
        _label(canvas, _short(data[i].total), Offset(cx, chart.bottom - h - 4),
            align: _A.centerAbove);
      }
      final d = data[i].day;
      _label(canvas, '${d.day}/${d.month}', Offset(cx, chart.bottom + 6),
          align: _A.centerBelow);
    }
  }

  double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final n = raw / mag;
    final nice = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
    return nice * mag;
  }

  void _label(Canvas c, String s, Offset at, {required _A align}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(color: textColor, fontSize: 10)),
      textDirection: TextDirection.ltr,
    )..layout();
    final o = switch (align) {
      _A.right => at - Offset(tp.width, tp.height / 2),
      _A.centerAbove => at - Offset(tp.width / 2, tp.height),
      _A.centerBelow => at - Offset(tp.width / 2, 0),
    };
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _BarPainter o) =>
      o.progress != progress || o.data != data || o.barColor != barColor;
}

enum _A { right, centerAbove, centerBelow }
