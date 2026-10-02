import 'package:flutter/material.dart';

import '../brand.dart';
import '../controller.dart';
import '../format.dart';
import '../theme.dart';

class ShowScope extends InheritedNotifier<ShowController> {
  const ShowScope({
    super.key,
    required ShowController controller,
    required super.child,
  }) : super(notifier: controller);

  static ShowController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ShowScope>();
    assert(scope != null, 'ShowScope missing');
    return scope!.notifier!;
  }
}

class ProductHeader extends StatelessWidget {
  const ProductHeader({super.key, required this.now});

  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              iconAsset,
              width: 36,
              height: 36,
              filterQuality: FilterQuality.medium,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              productName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: condensed(26, weight: FontWeight.w700),
            ),
          ),
          LinkLamp(
            enabled: controller.link.enabled,
            error: controller.linkError,
            clock: controller.link.emitClock,
          ),
          const SizedBox(width: 10),
          Text(formatWall(now), style: clockStyle(16, boothMuted)),
        ],
      ),
    );
  }
}

class LinkLamp extends StatelessWidget {
  const LinkLamp({
    super.key,
    required this.enabled,
    required this.clock,
    this.error,
  });

  final bool enabled;
  final bool clock;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final color = !enabled
        ? boothMuted
        : error == null
        ? boothGreen
        : boothRed;
    final label = enabled ? 'LINK' : 'OFF';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
        if (enabled && clock) ...[
          const SizedBox(width: 6),
          const Icon(Icons.schedule, size: 14, color: boothMuted),
        ],
      ],
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    if (label.isEmpty) return const SizedBox.shrink();
    final color = switch (label) {
      'LIVE' => boothGreen,
      'HOLD' => boothAmber,
      'OVER' || 'DUE' || 'LATE' => boothRed,
      'NEXT' => boothBlue,
      _ => boothMuted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}
