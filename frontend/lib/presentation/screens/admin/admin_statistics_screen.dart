import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:frontend/l10n/app_localizations.dart';
import '../../../di/service_locator.dart';
import '../../../logic/controllers/admin_statistics_controller.dart';
import '../../../theme/app_theme.dart';
import '../../widgets/statistics_filter_sheet.dart';

// ── Design tokens — 60/30/10 ─────────────────────────────────────────────────

// 60 % — Neutral
// card background is Colors.white (pure white)

// 30 % — Primary purple (anchored to AppColors)
const _purpleDark    = AppColors.primaryDark;    // #422969
const _purplePrimary = AppColors.primary;        // #663d99
const _purplePale    = AppColors.secondary;       // icon bg tint (#ede8f5)

// 10 % — Gold accent (bars + female donut ONLY — no yellow text anywhere)
const _goldDeep   = AppColors.accentDark;         // Without-Group icon (#c9a01f)
const _goldPale   = Color(0xFFFEF3C7);            // Without-Group icon bg (light tint)

// Typography — dark slate / cool gray (never yellow)
const _textDark  = AppColors.text;                // KPI numbers (#1a1a2e)
const _textMid   = Color(0xFF334155);             // card titles + bar labels (mid slate)
const _textMuted = AppColors.mutedForeground;     // subtitles + percentages (#7c6f9a)

// Chart internals
const _trackColor = Color(0xFFF1F5F9);
const _mutedBar   = Color(0xFFCBD5E1);            // "Not set" / "Other"

// Single-hue bars — same platform colors as the rest of the app; depth via opacity
const _barPurple = AppColors.primary;   // #663d99 — matches the Add Level button
const _barGold   = AppColors.accent;    // #f0c230

// Single shared card shadow
const _shadow = BoxShadow(
  color: Color(0x0D000000), // ≈ 5 % black — matches the app card shadow
  blurRadius: 8,
  spreadRadius: 0,
  offset: Offset(0, 2),
);

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = getIt<AdminStatisticsController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ListenableBuilder(
        listenable: ctrl,
        builder: (context, _) {
          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (ctrl.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppColors.error, size: 40),
                  const SizedBox(height: 12),
                  Text(ctrl.error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: ctrl.refresh, child: const Text('Retry')),
                ],
              ),
            );
          }

          final l10n = AppLocalizations.of(context)!;
          return SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              width: 3,
                              height: 20,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.statisticsTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      _FilterButton(
                        activeCount: ctrl.activeFilter.activeCount,
                        onTap: () => showStatisticsFilterDialog(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ═══════════════════════════════════════════════════════════
                        // STUDENTS
                        // ═══════════════════════════════════════════════════════════
                        _sectionHeader(l10n.studentsSectionTitle),
                  const SizedBox(height: 20),

                  // KPI row
                  LayoutBuilder(builder: (ctx, c) {
                    final isWide = c.maxWidth >= 600;
                    final half = isWide ? (c.maxWidth - 16) / 2 : c.maxWidth;
                    return Wrap(spacing: 16, runSpacing: 16, children: [
                      SizedBox(
                        width: half,
                        child: _kpiCard(
                          icon: Icons.school_rounded,
                          label: 'Total Students',
                          value: '${ctrl.totalStudents}',
                          note: 'Active members',
                          iconBg: _purplePale,
                          iconColor: _purpleDark,
                        ),
                      ),
                      SizedBox(
                        width: half,
                        child: _kpiCard(
                          icon: Icons.group_off_rounded,
                          label: 'Without Group',
                          value: '${ctrl.unassignedStudents}',
                          note: 'Pending assignment',
                          iconBg: _goldPale,
                          iconColor: _goldDeep,
                        ),
                      ),
                    ]);
                  }),
                  const SizedBox(height: 20),

                  // Chart grid
                  LayoutBuilder(builder: (ctx, c) {
                    final isWide = c.maxWidth >= 600;
                    final half = isWide ? (c.maxWidth - 16) / 2 : c.maxWidth;
                    return Wrap(spacing: 16, runSpacing: 16, children: [
                      SizedBox(
                        width: half,
                        child: _donutCard(
                          title: 'Gender Distribution',
                          subtitle: 'Male vs. female breakdown',
                          data: ctrl.studentsByGender,
                          unit: 'students',
                        ),
                      ),
                      SizedBox(
                        width: half,
                        child: ctrl.studentsByLevel.isNotEmpty
                            ? _barCard(
                                title: 'By Level',
                                subtitle: 'Students per curriculum level',
                                data: ctrl.studentsByLevel,
                                baseColor: _barPurple,
                                labelMapper: (k) => ctrl.levelNames[k] ?? k,
                              )
                            : _emptyCard('No level data'),
                      ),
                      SizedBox(
                        width: half,
                        child: ctrl.studentsByAge.isNotEmpty
                            ? _barCard(
                                title: 'Age Distribution',
                                subtitle: 'Students by individual age',
                                note: 'avg ${ctrl.studentAverageAge.toStringAsFixed(1)}',
                                data: ctrl.studentsByAge,
                                baseColor: _barGold,
                              )
                            : _emptyCard('No age data'),
                      ),
                      SizedBox(
                        width: half,
                        child: ctrl.studentsByLocation.isNotEmpty
                            ? _barCard(
                                title: 'By Location',
                                subtitle: 'Top 5 student locations',
                                data: ctrl.studentsByLocation,
                                baseColor: _barPurple,
                              )
                            : _emptyCard('No location data'),
                      ),
                    ]);
                  }),
                  const SizedBox(height: 44),

                  // ═══════════════════════════════════════════════════════════
                  // INSTRUCTORS
                  // ═══════════════════════════════════════════════════════════
                  _sectionHeader(l10n.instructorsSectionTitle),
                  const SizedBox(height: 20),

                  // KPI row (single)
                  _kpiCard(
                    icon: Icons.person_rounded,
                    label: 'Total Instructors',
                    value: '${ctrl.totalInstructors}',
                    note: 'Platform instructors',
                    iconBg: _purplePale,
                    iconColor: _purpleDark,
                  ),
                  const SizedBox(height: 20),

                  // Chart grid
                  LayoutBuilder(builder: (ctx, c) {
                    final isWide = c.maxWidth >= 600;
                    final half = isWide ? (c.maxWidth - 16) / 2 : c.maxWidth;
                    return Wrap(spacing: 16, runSpacing: 16, children: [
                      SizedBox(
                        width: half,
                        child: _donutCard(
                          title: 'Gender Distribution',
                          subtitle: 'Male vs. female breakdown',
                          data: ctrl.instructorsByGender,
                          unit: 'instructors',
                        ),
                      ),
                      SizedBox(
                        width: half,
                        child: ctrl.instructorsByLocation.isNotEmpty
                            ? _barCard(
                                title: 'By Location',
                                subtitle: 'Top 5 instructor locations',
                                data: ctrl.instructorsByLocation,
                                baseColor: _barPurple,
                              )
                            : _emptyCard('No location data'),
                      ),
                      SizedBox(
                        width: half,
                        child: ctrl.instructorsByAge.isNotEmpty
                            ? _barCard(
                                title: 'Age Distribution',
                                subtitle: 'Instructors by individual age',
                                note: 'avg ${ctrl.instructorAverageAge.toStringAsFixed(1)}',
                                data: ctrl.instructorsByAge,
                                baseColor: _barGold,
                              )
                            : _emptyCard('No age data'),
                      ),
                    ]);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
        },
      ),
    );
  }

  // ── Section header with divider ───────────────────────────────────────────

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: _purplePrimary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: _purpleDark,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  // ── Premium card shell ────────────────────────────────────────────────────

  Widget _premiumCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [_shadow],
      ),
      child: child,
    );
  }

  // ── KPI card ──────────────────────────────────────────────────────────────

  Widget _kpiCard({
    required IconData icon,
    required String label,
    required String value,
    required Color iconBg,
    required Color iconColor,
    String? note,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [_shadow],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    height: 1.1,
                  ),
                ),
                if (note != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    note,
                    style: const TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card header (title + subtitle + optional avg note) ────────────────────

  Widget _cardHeader(String title, {String? subtitle, String? note}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textMid,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ],
              ),
            ),
            if (note != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12),
                child: Text(
                  note,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ── Empty placeholder ─────────────────────────────────────────────────────

  Widget _emptyCard(String message) {
    return _premiumCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(
            message,
            style: const TextStyle(fontSize: 13, color: _textMuted),
          ),
        ),
      ),
    );
  }

  // ── Donut chart card ──────────────────────────────────────────────────────

  Widget _donutCard({
    required String title,
    String? subtitle,
    required Map<String, int> data,
    required String unit,
  }) {
    final total = data.values.fold(0, (a, b) => a + b);
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    Color colorFor(String key) {
      final k = key.toLowerCase();
      if (k == 'male') return _barPurple;
      if (k == 'female') return _barGold;
      if (k == 'not set') return _mutedBar;
      final idx = entries.indexWhere((e) => e.key == key).clamp(0, 2);
      return [_barPurple, _barGold, _barPurple.withValues(alpha: 0.5)][idx];
    }

    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(title, subtitle: subtitle),
          if (total == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 28),
                child: Text('No data', style: TextStyle(color: _textMuted, fontSize: 13)),
              ),
            )
          else ...[
            Center(
              child: SizedBox(
                width: 148,
                height: 148,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(148, 148),
                      painter: _DonutPainter(
                        data: Map.fromEntries(entries),
                        colors: entries.map((e) => colorFor(e.key)).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(entries.first.value / total * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _capitalize(entries.first.key),
                          style: const TextStyle(
                            fontSize: 12,
                            color: _textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            ...entries.map((e) {
              final color = colorFor(e.key);
              final pct = total > 0 ? (e.value / total * 100).round() : 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _capitalize(e.key),
                        style: const TextStyle(
                          fontSize: 13,
                          color: _textMid,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${e.value} $unit · $pct%',
                      style: const TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  // ── Bar chart card ────────────────────────────────────────────────────────

  Widget _barCard({
    required String title,
    String? subtitle,
    String? note,
    required Map<String, int> data,
    required Color baseColor,
    String Function(String)? labelMapper,
  }) {
    final total = data.values.fold(0, (a, b) => a + b);
    final maxVal = data.values.fold(0, (a, b) => a > b ? a : b);
    final entries = data.entries.toList();

    return _premiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(title, subtitle: subtitle, note: note),
          ...entries.map((e) {
            final key = e.key;
            final val = e.value;
            final label = labelMapper != null ? labelMapper(key) : key;
            final isMuted = key == 'Not set' || key == 'Other';
            // Same hue — depth via opacity scaled to the value.
            final double alpha = (maxVal > 0 ? 0.40 + 0.60 * (val / maxVal) : 1.0)
                .clamp(0.40, 1.0)
                .toDouble();
            final color = isMuted ? _mutedBar : baseColor.withValues(alpha: alpha);
            return _barRow(
              label: label,
              value: val,
              maxValue: maxVal,
              total: total,
              color: color,
              isMuted: isMuted,
            );
          }),
        ],
      ),
    );
  }

  Widget _barRow({
    required String label,
    required int value,
    required int maxValue,
    required int total,
    required Color color,
    bool isMuted = false,
  }) {
    final fraction = maxValue > 0 ? value / maxValue : 0.0;
    final pct = total > 0 ? (value / total * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isMuted ? _textMuted : _textMid,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$value · $pct%',
                style: const TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (ctx, c) {
              final barWidth = fraction * c.maxWidth;
              return Stack(
                children: [
                  Container(
                    height: 8,
                    width: c.maxWidth,
                    decoration: const BoxDecoration(
                      color: _trackColor,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    height: 8,
                    width: barWidth,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ── Filter button ─────────────────────────────────────────────────────────────

class _FilterButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  const _FilterButton({required this.activeCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = activeCount > 0;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: isActive ? Colors.white : AppColors.mutedForeground,
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppColors.mutedForeground,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Donut painter ─────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final List<Color> colors;

  const _DonutPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.30;
    final entries = data.entries.toList();
    double startAngle = -math.pi / 2;

    for (int i = 0; i < entries.length; i++) {
      final sweep = 2 * math.pi * entries[i].value / total;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweep,
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.data != data || old.colors != colors;
}
