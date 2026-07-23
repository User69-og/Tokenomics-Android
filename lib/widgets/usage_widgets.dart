import 'package:flutter/material.dart';
import 'package:tokenomics/theme/app_theme.dart';
import '../models/usage_data.dart';
import 'dart:math' as math;

// ── Usage Bar ──────────────────────────────────────────────────────────────

class UsageBar extends StatelessWidget {
  final UsageMetric metric;
  final Color color;
  final bool compact;

  const UsageBar({
    super.key,
    required this.metric,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                metric.label,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (metric.unit != '%')
              Text(
                metric.hasLimit
                    ? '${_formatNumber(metric.used)} / ${_formatNumber(metric.limit!)}'
                    : _formatNumber(metric.used),
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Container(
                    height: compact ? 4 : 6,
                    width: constraints.maxWidth,
                    color: AppTheme.border,
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: compact ? 4 : 6,
                    width: constraints.maxWidth * metric.fraction,
                    decoration: BoxDecoration(
                      color: _barColor(metric.fraction, color),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Color _barColor(double fraction, Color base) {
    if (fraction > 0.9) return AppTheme.error;
    if (fraction > 0.75) return AppTheme.warning;
    return base;
  }

  String _formatNumber(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toStringAsFixed(0);
  }
}

// ── Connection Status Badge ────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final ConnectionStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return AppTheme.success;
      case ConnectionStatus.error:
        return AppTheme.error;
      case ConnectionStatus.loading:
        return AppTheme.warning;
      case ConnectionStatus.notConfigured:
        return AppTheme.textMuted;
    }
  }

  String get _label {
    switch (status) {
      case ConnectionStatus.connected:
        return 'LIVE';
      case ConnectionStatus.error:
        return 'ERROR';
      case ConnectionStatus.loading:
        return 'SYNCING';
      case ConnectionStatus.notConfigured:
        return 'NOT SET';
    }
  }
}

// ── Radial Usage Ring (menu-bar style) ────────────────────────────────────

class UsageRing extends StatelessWidget {
  final double fraction;
  final Color color;
  final String label;
  final double size;

  const UsageRing({
    super.key,
    required this.fraction,
    required this.color,
    required this.label,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _RingPainter(fraction: fraction, color: color),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: size * 0.22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double fraction;
  final Color color;

  const _RingPainter({required this.fraction, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const strokeWidth = 4.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = AppTheme.border
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );

    if (fraction > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * fraction,
        false,
        Paint()
          ..color = fraction > 0.9
              ? AppTheme.error
              : fraction > 0.75
                  ? AppTheme.warning
                  : color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}

// ── Section Header ─────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const Expanded(child: SizedBox()),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────

class EmptyStateWidget extends StatelessWidget {
  final String providerName;
  final Color color;
  final VoidCallback onAdd;

  const EmptyStateWidget({
    super.key,
    required this.providerName,
    required this.color,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(Icons.add_rounded, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No $providerName accounts',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an account to start\ntracking your usage',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Add $providerName Account'),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
