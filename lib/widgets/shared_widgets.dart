import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/app_models.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'NOUN Update',
        child: Image.asset(
          'assets/images/noun_update_logo.png',
          width: compact ? 54 : 210,
          height: compact ? 48 : 210,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      );
}

class DemoDataBanner extends StatelessWidget {
  const DemoDataBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFDFAB)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: Color(0xFF8A5B16)),
            SizedBox(width: 9),
            Expanded(
              child: Text(
                'Preview data is showing until the live API is connected.',
                style: TextStyle(
                  color: Color(0xFF6E4915),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class ToolTile extends StatelessWidget {
  const ToolTile({required this.tool, required this.onTap, super.key});

  final AppTool tool;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(17),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColours.mint,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.icon, color: AppColours.green700),
                    ),
                    if (tool.premium)
                      const Positioned(
                        right: -5,
                        top: -5,
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          size: 17,
                          color: AppColours.warning,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ResourceCard extends StatelessWidget {
  const ResourceCard({
    required this.resource,
    required this.onTap,
    super.key,
    this.onSave,
  });

  final LearningResource resource;
  final VoidCallback onTap;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColours.mint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(resource.icon, color: AppColours.green700),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            resource.category.toUpperCase(),
                            style: const TextStyle(
                              color: AppColours.green700,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (resource.isPremium)
                            const Text(
                              'PREMIUM',
                              style: TextStyle(
                                color: AppColours.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        resource.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        resource.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColours.muted,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onSave,
                  icon: Icon(
                    resource.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: AppColours.green700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class ReadinessRing extends StatelessWidget {
  const ReadinessRing({required this.value, super.key, this.size = 84});

  final int value;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(value / 100),
          child: Center(
            child: Text(
              '$value%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      );
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final centre = rect.center;
    final radius = math.min(size.width, size.height) / 2 - 6;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = Colors.white.withValues(alpha: .18);
    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7
      ..color = AppColours.green500;
    canvas.drawCircle(centre, radius, base);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(0.0, 1.0).toDouble(),
      false,
      progress,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.value != value;
}

String formatNaira(int amountKobo) {
  final negative = amountKobo < 0;
  final naira = amountKobo.abs() ~/ 100;
  final digits = naira.toString();
  final chunks = <String>[];
  for (var end = digits.length; end > 0; end -= 3) {
    final start = end - 3 < 0 ? 0 : end - 3;
    chunks.insert(0, digits.substring(start, end));
  }
  return '${negative ? '-' : ''}₦${chunks.join(',')}';
}
