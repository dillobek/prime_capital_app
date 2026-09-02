import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../core/i18n.dart';
import '../core/models.dart';

/// Chart time range. The backend has no historical income time-series
/// endpoint (only the current balance + monthlyChange %, see
/// `ApiClient.getBalances`), so — exactly like the original decorative SVG
/// chart in Webapp's `web-app.tsx` — every period below is a curve
/// *synthesized* from the real current numbers, not true day-by-day
/// history. Its vertical position reflects each product's real balance
/// amount and its slope/steepness reflects the real `monthlyChange` % and
/// direction, so the chart visibly moves whenever those real numbers change
/// (e.g. edited from the admin panel) instead of staying a static picture.
enum ChartPeriod { daily, weekly, monthly, halfYear, yearly }

extension _ChartPeriodX on ChartPeriod {
  String get labelKey => switch (this) {
        ChartPeriod.daily => 'wa.chart.period.1d',
        ChartPeriod.weekly => 'wa.chart.period.1w',
        ChartPeriod.monthly => 'wa.chart.period.1m',
        ChartPeriod.halfYear => 'wa.chart.period.6m',
        ChartPeriod.yearly => 'wa.chart.period.1y',
      };

  /// How many points to plot for this range — choppier for a single day,
  /// smoother for a year.
  int get pointCount => switch (this) {
        ChartPeriod.daily => 8,
        ChartPeriod.weekly => 7,
        ChartPeriod.monthly => 10,
        ChartPeriod.halfYear => 6,
        ChartPeriod.yearly => 12,
      };

  /// How many up/down "waves" to fit across the range — purely cosmetic
  /// texture on top of the real trend line.
  double get waveCycles => switch (this) {
        ChartPeriod.daily => 2.4,
        ChartPeriod.weekly => 2.0,
        ChartPeriod.monthly => 1.6,
        ChartPeriod.halfYear => 1.1,
        ChartPeriod.yearly => 1.3,
      };
}

/// Builds a (0..1) line for one product, driven by its real current
/// `amount` (vertical position, relative to the larger of the two
/// products) and its real `monthlyChange` % (slope direction +
/// steepness). A flat 0% change renders as a flat line, matching the
/// neutral state already used on the home-screen balance cards.
List<double> _seriesPoints({
  required ChartPeriod period,
  required double amount,
  required double maxAmount,
  required double monthlyChange,
  required double wavePhase,
}) {
  final count = period.pointCount;
  final ratio = maxAmount > 0 ? (amount / maxAmount).clamp(0.0, 1.0) : 0.5;
  final baseFrac = 0.22 + ratio * 0.56;

  final magnitude = monthlyChange.abs().clamp(0, 80) / 80;
  final amplitude = monthlyChange == 0 ? 0.0 : 0.06 + magnitude * 0.26;
  final direction = monthlyChange > 0 ? 1.0 : (monthlyChange < 0 ? -1.0 : 0.0);

  return List.generate(count, (i) {
    final t = count <= 1 ? 0.0 : i / (count - 1);
    final trend = baseFrac + direction * amplitude * (t - 0.5);
    final wave = amplitude == 0
        ? 0.0
        : math.sin(t * period.waveCycles * 2 * math.pi + wavePhase) * amplitude * 0.16;
    return (trend + wave).clamp(0.05, 0.95);
  });
}

/// Small decorative line chart for the Home screen, redrawn with
/// CustomPainter instead of the Webapp's inline SVG polylines — same two
/// series (PHP Invest / Prime Capital), now driven by the real balances
/// passed in from `HomeScreen`. The period pill in the top-right is a real
/// dropdown (kunlik/haftalik/oylik/yarim yillik/yillik); Webapp's own
/// period `<select>` has no handler at all, so this is one step ahead of it.
class IncomeChartCard extends StatefulWidget {
  const IncomeChartCard({super.key, required this.balances});

  final List<Balance> balances;

  @override
  State<IncomeChartCard> createState() => _IncomeChartCardState();
}

class _IncomeChartCardState extends State<IncomeChartCard> {
  ChartPeriod _period = ChartPeriod.halfYear;

  Balance? _findBalance(String id) {
    for (final b in widget.balances) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final prime = _findBalance(kProductPrimeCapital);
    final php = _findBalance(kProductPhpInvest);
    final primeAmount = prime?.amount ?? 0;
    final phpAmount = php?.amount ?? 0;
    final maxAmount = math.max(primeAmount, phpAmount);

    final bluePoints = _seriesPoints(
      period: _period,
      amount: primeAmount,
      maxAmount: maxAmount,
      monthlyChange: prime?.monthlyChange ?? 0,
      wavePhase: 0.6,
    );
    final cyanPoints = _seriesPoints(
      period: _period,
      amount: phpAmount,
      maxAmount: maxAmount,
      monthlyChange: php?.monthlyChange ?? 0,
      wavePhase: 2.4,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t(context, 'wa.chart.title'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                _PeriodPicker(
                  period: _period,
                  onChanged: (value) => setState(() => _period = value),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(children: [
              _legendDot(PrimeColors.cyan),
              const SizedBox(width: 6),
              const Text('PHP Invest', style: TextStyle(fontSize: 12, color: PrimeColors.slate)),
              const SizedBox(width: 14),
              _legendDot(PrimeColors.blue),
              const SizedBox(width: 6),
              const Text('Prime Capital', style: TextStyle(fontSize: 12, color: PrimeColors.slate)),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              width: double.infinity,
              child: TweenAnimationBuilder<double>(
                key: ValueKey((_period, primeAmount, phpAmount, prime?.monthlyChange, php?.monthlyChange)),
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 380),
                curve: Curves.easeOut,
                builder: (context, progress, _) => CustomPaint(
                  painter: _ChartPainter(cyanPoints: cyanPoints, bluePoints: bluePoints, progress: progress),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _PeriodPicker extends StatelessWidget {
  const _PeriodPicker({required this.period, required this.onChanged});
  final ChartPeriod period;
  final ValueChanged<ChartPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ChartPeriod>(
      initialValue: period,
      onSelected: onChanged,
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: PrimeColors.card,
      elevation: 8,
      shadowColor: PrimeColors.ink.withOpacity(0.18),
      itemBuilder: (context) => [
        for (final value in ChartPeriod.values)
          PopupMenuItem(
            value: value,
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  value == period ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: value == period ? PrimeColors.blue : PrimeColors.border,
                ),
                const SizedBox(width: 10),
                Text(
                  t(context, value.labelKey),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: value == period ? FontWeight.w700 : FontWeight.w500,
                    color: value == period ? PrimeColors.ink : PrimeColors.slate,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: PrimeColors.fieldFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t(context, period.labelKey), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: PrimeColors.slate)),
            const SizedBox(width: 3),
            const Icon(Icons.expand_more_rounded, size: 15, color: PrimeColors.slate),
          ],
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({required this.cyanPoints, required this.bluePoints, this.progress = 1});

  final List<double> cyanPoints;
  final List<double> bluePoints;

  /// 0..1 draw-in progress, animated whenever the period or the underlying
  /// real data (amount / monthlyChange) changes.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = PrimeColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _drawLine(canvas, size, cyanPoints, PrimeColors.cyan);
    _drawLine(canvas, size, bluePoints, PrimeColors.blue);
  }

  void _drawLine(Canvas canvas, Size size, List<double> points, Color color) {
    final full = Path();
    for (var i = 0; i < points.length; i++) {
      final x = size.width * i / (points.length - 1);
      final y = size.height * (1 - points[i]);
      if (i == 0) {
        full.moveTo(x, y);
      } else {
        full.lineTo(x, y);
      }
    }

    final metrics = full.computeMetrics().toList();
    final animated = metrics.isEmpty ? full : metrics.first.extractPath(0, metrics.first.length * progress);

    canvas.drawPath(
      animated,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) =>
      oldDelegate.cyanPoints != cyanPoints || oldDelegate.bluePoints != bluePoints || oldDelegate.progress != progress;
}
