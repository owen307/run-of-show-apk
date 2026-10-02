import 'package:flutter/material.dart';

import '../engine.dart';
import '../format.dart';
import '../theme.dart';
import 'widgets.dart';

class StageScreen extends StatelessWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ShowScope.of(context);
    final now = controller.clock();
    final show = controller.show;
    final view = controller.project(now);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  show.displayTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: condensed(28, weight: FontWeight.w700),
                ),
              ),
              Text(
                view.showElapsedSec == 0
                    ? planLine(show)
                    : 'Show ${formatSpan(view.showElapsedSec)}',
                style: const TextStyle(color: boothMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            planLine(show),
            style: const TextStyle(color: boothMuted, fontSize: 13),
          ),
        ),
        const Divider(height: 1, color: boothLine),
        Expanded(
          child: show.cues.isEmpty
              ? const Center(
                  child: Text(
                    'The stage list is empty. Add cues in Edit.',
                    style: TextStyle(color: boothMuted, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  itemCount: show.cues.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: boothLine),
                  itemBuilder: (context, index) {
                    final cue = show.cues[index];
                    final status = rowStatus(show, view, index, now);
                    final live = view.activeIndex == index;
                    return Container(
                      color: live ? boothAmber.withValues(alpha: 0.08) : null,
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 3,
                            height: 46,
                            color: live ? boothAmber : Colors.transparent,
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 32,
                            child: Text(
                              cueNumber(index),
                              style: clockStyle(
                                18,
                                live ? boothAmber : boothMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cue.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (cue.notes.isNotEmpty)
                                  Text(
                                    cue.notes,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: boothMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      cue.timingLabel,
                                      style: clockStyle(14, boothText),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusChip(label: status),
                                    if (live) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        formatSpan(view.remainingSec),
                                        style: clockStyle(
                                          14,
                                          heroColor(
                                            view.heroLabel,
                                            view.remainingSec,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!live)
                            OutlinedButton(
                              onPressed: () => controller.take(index),
                              child: const Text('TAKE'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
